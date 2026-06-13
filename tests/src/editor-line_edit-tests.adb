with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Containers; use Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Editor.Clipboard;
with Editor.Command_Palette;
with Editor.Commands;
with Editor.Buffers;
with Editor.Cursors; use Editor.Cursors;
with Editor.Executor;
with Editor.History;
with Editor.Input_Bridge;
with Editor.Keybindings;
with Editor.Keybinding_Config;
with Editor.Messages;
with Editor.Navigation;
with Editor.Navigation_History;
with Editor.Render_Model;
with Editor.Selection;
with Editor.State;
with Editor.Unicode;
with Editor.UTF8;
with Editor.Workspace_Persistence;
with Text_Buffer;

package body Editor.Line_Edit.Tests is

   use type Editor.Keybinding_Config.Keybinding_Config_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Commands.Command_Kind;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Keybindings.Binding_Result;

   overriding function Name
     (T : Line_Edit_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Line_Edit");
   end Name;

   procedure Set_Caret
     (S   : in out Editor.State.State_Type;
      Pos : Cursor_Index)
   is
   begin
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => Pos,
            Anchor                => Pos,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
   end Set_Caret;

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

   procedure Assert_Navigation_Counts
     (S             : Editor.State.State_Type;
      Expected_Back : Natural;
      Expected_Fwd  : Natural;
      Why           : String)
   is
   begin
      Assert
        (Editor.Navigation_History.Back_Count (S.Navigation_History) = Expected_Back,
         Why & ": navigation back stack changed");
      Assert
        (Editor.Navigation_History.Forward_Count (S.Navigation_History) = Expected_Fwd,
         Why & ": navigation forward stack changed");
   end Assert_Navigation_Counts;

   function Message_Text (S : Editor.State.State_Type) return String is
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      M := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (M);
      else
         return "";
      end if;
   end Message_Text;

   procedure Assert_Caret_Row_Col
     (S              : Editor.State.State_Type;
      Expected_Row   : Natural;
      Expected_Col   : Natural;
      Why            : String)
   is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Assert (S.Carets.Length > 0, Why & ": expected a caret");
      Editor.Navigation.Line_Column_For_Index
        (S, Natural (S.Carets (S.Carets.First_Index).Pos), Row, Col);
      Assert (Row = Expected_Row, Why & ": caret row mismatch");
      Assert (Col = Expected_Col, Why & ": caret column mismatch");
   end Assert_Caret_Row_Col;



   function Buffer_Text (S : Editor.State.State_Type) return String is
   begin
      return Text_Buffer.UTF8_Text (S.Buffer);
   end Buffer_Text;

   procedure Assert_Buffer_Text
     (S        : Editor.State.State_Type;
      Expected : String;
      Why      : String)
   is
   begin
      Assert (Buffer_Text (S) = Expected, Why & ": buffer text mismatch");
   end Assert_Buffer_Text;

   procedure Assert_Line_Join_Coherent
     (S                    : Editor.State.State_Type;
      Expected_Text        : String;
      Expected_Line_Count  : Natural;
      Expected_Row         : Natural;
      Expected_Col         : Natural;
      Expected_Undo_Count  : Natural;
      Expected_Redo_Count  : Natural;
      Expected_Message     : String;
      Expected_Dirty       : Boolean;
      Expected_Selection   : Boolean;
      Expected_Clipboard   : Unbounded_String;
      Expected_Back_Count  : Natural;
      Expected_Fwd_Count   : Natural;
      Why                  : String)
   is
   begin
      Assert_Buffer_Text (S, Expected_Text, Why);
      Assert (Editor.State.Line_Count (S) = Expected_Line_Count,
              Why & ": logical line count mismatch");
      Assert_Caret_Row_Col (S, Expected_Row, Expected_Col, Why);
      Assert (Natural (Editor.History.Undo_Stack.Length) = Expected_Undo_Count,
              Why & ": undo stack count mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Expected_Redo_Count,
              Why & ": redo stack count mismatch");
      Assert (Message_Text (S) = Expected_Message,
              Why & ": command message mismatch");
      Assert (Editor.State.Is_Dirty (S) = Expected_Dirty,
              Why & ": dirty flag mismatch");
      Assert (Editor.Selection.Has_Selection (S) = Expected_Selection,
              Why & ": selection state mismatch");
      Assert (Editor.Clipboard.Get_Text = Expected_Clipboard,
              Why & ": clipboard text changed");
      Assert_Navigation_Counts (S, Expected_Back_Count, Expected_Fwd_Count, Why);
   end Assert_Line_Join_Coherent;


   type Word_Delete_Test_Direction is
     (Word_Delete_Test_Previous,
      Word_Delete_Test_Next);

   function Caret_From_Marked (Marked : String) return Cursor_Index is
      Pos : Natural := 0;
   begin
      for I in Marked'Range loop
         if Marked (I) = '|' then
            return Cursor_Index (Pos);
         else
            Pos := Pos + 1;
         end if;
      end loop;

      Assert (False, "marked word-delete fixture has no caret marker");
      return 0;
   end Caret_From_Marked;

   function Strip_Caret_Marker (Marked : String) return String is
      Result : String (1 .. Marked'Length) := (others => ASCII.NUL);
      Last   : Natural := 0;
   begin
      for I in Marked'Range loop
         if Marked (I) /= '|' then
            Last := Last + 1;
            Result (Last) := Marked (I);
         end if;
      end loop;

      if Last = 0 then
         return "";
      else
         return Result (1 .. Last);
      end if;
   end Strip_Caret_Marker;

   function Slice_Zero_Based
     (Text      : String;
      First_Pos : Natural;
      Last_Pos  : Natural) return String
   is
   begin
      if Last_Pos <= First_Pos then
         return "";
      else
         return Text (Text'First + First_Pos .. Text'First + Last_Pos - 1);
      end if;
   end Slice_Zero_Based;

   procedure Assert_Word_Delete_Transform
     (Direction    : Word_Delete_Test_Direction;
      Before       : String;
      Expected     : String;
      Removed_Text : String;
      Why          : String)
   is
      S              : Editor.State.State_Type;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Text    : constant String := Strip_Caret_Marker (Before);
      Before_Caret   : constant Cursor_Index := Caret_From_Marked (Before);
      Expected_Text   : constant String := Strip_Caret_Marker (Expected);
      Expected_Caret  : constant Cursor_Index := Caret_From_Marked (Expected);
      Delete_Start    : Natural := 0;
      Delete_End      : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, Before_Caret);

      if Direction = Word_Delete_Test_Previous then
         Delete_Start := Natural (Expected_Caret);
         Delete_End := Natural (Before_Caret);
      else
         Delete_Start := Natural (Before_Caret);
         Delete_End := Natural (Before_Caret) + Removed_Text'Length;
      end if;

      Assert
        (Slice_Zero_Based (Before_Text, Delete_Start, Delete_End) = Removed_Text,
         Why & ": removed text mismatch");
      Assert
        (Slice_Zero_Based (Before_Text, 0, Delete_Start)
         & Slice_Zero_Based (Before_Text, Delete_End, Before_Text'Length)
         = Expected_Text,
         Why & ": computed delete range does not reconstruct expected text");

      if Direction = Word_Delete_Test_Previous then
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Word_Delete_Previous);
         Assert (Message_Text (S) = "Deleted previous word",
                 Why & ": delete-previous message mismatch");
      else
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Word_Delete_Next);
         Assert (Message_Text (S) = "Deleted next word",
                 Why & ": delete-next message mismatch");
      end if;

      Assert_Buffer_Text (S, Expected_Text, Why);
      Assert (S.Carets (S.Carets.First_Index).Pos = Expected_Caret,
              Why & ": caret mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              Why & ": text-changing word delete must create one undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              Why & ": text-changing word delete must leave redo empty");
      Assert (Editor.State.Is_Dirty (S),
              Why & ": text-changing word delete must dirty a clean buffer");
      Assert (not Editor.Selection.Has_Selection (S),
              Why & ": selection must be valid or empty after mutation");
      Assert (Editor.Clipboard.Has_Text
              and then Editor.Clipboard.Get_Text = Before_Clip,
              Why & ": word delete must not mutate clipboard");
      Assert_Navigation_Counts (S, 0, 0,
                                Why & ": word delete must not record navigation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, Before_Text,
                          Why & ": undo must restore exact pre-delete text after removing " & Removed_Text);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, Expected_Text,
                          Why & ": redo must restore exact post-delete text");
   end Assert_Word_Delete_Transform;

   procedure Assert_Word_Delete_No_Op
     (Direction : Word_Delete_Test_Direction;
      Before    : String;
      Why       : String)
   is
      S           : Editor.State.State_Type;
      Before_Text : constant String := Strip_Caret_Marker (Before);
      Before_Clip : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Redo_Count  : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Seed Word");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);

      Editor.State.Load_Text (S, Before_Text);
      Set_Caret (S, Caret_From_Marked (Before));

      if Direction = Word_Delete_Test_Previous then
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Word_Delete_Previous);
      else
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Word_Delete_Next);
      end if;

      Assert_Buffer_Text (S, Before_Text, Why);
      Assert (Message_Text (S) = "Nothing to delete",
              Why & ": no-op message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              Why & ": no-op word delete must not create undo");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              Why & ": no-op word delete must preserve redo stack");
      Assert (Editor.Clipboard.Has_Text
              and then Editor.Clipboard.Get_Text = Before_Clip,
              Why & ": no-op word delete must not mutate clipboard");
   end Assert_Word_Delete_No_Op;

   procedure Test_Phase381_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Line_Delete) = "edit.line.delete",
         "delete-line stable name mismatch");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Line_Duplicate) = "edit.line.duplicate",
         "duplicate-line stable name mismatch");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Line_Move_Up) = "edit.line.move-up",
         "move-up stable name mismatch");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Line_Move_Down) = "edit.line.move-down",
         "move-down stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Line_Delete).Category =
         Editor.Commands.Edit_Category,
         "line delete must be an Edit command");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Line_Delete),
         "line delete must be bindable");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Line_Duplicate),
         "line duplicate must be bindable");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Line_Move_Up),
         "line move-up must be bindable");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Line_Move_Down),
         "line move-down must be bindable");
   end Test_Phase381_Command_Descriptors;

   procedure Test_Phase381_Delete_Current_Line_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 4);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);

      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & "three",
         "delete-line must remove the caret line and its terminator");
      Assert (Message_Text (S) = "Deleted line", "delete-line message mismatch");
      Assert (Editor.State.Is_Dirty (S), "delete-line must dirty clean buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "delete-line must create one undo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & "two" & ASCII.LF & "three",
         "undo after delete-line must restore exact text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & "three",
         "redo after delete-line must restore exact edited text");
   end Test_Phase381_Delete_Current_Line_Undo_Redo;

   procedure Test_Phase381_Duplicate_Current_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Set_Caret (S, 4);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);

      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "two" & ASCII.LF & "two" & ASCII.LF & "three",
         "duplicate-line must insert an exact copy below the caret line");
      Assert (Message_Text (S) = "Duplicated line", "duplicate-line message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "duplicate-line must create one undo entry");
   end Test_Phase381_Duplicate_Current_Line;

   procedure Test_Phase381_Move_Line_Up_Down_And_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Redo_Count : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Set_Caret (S, 4);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Up);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "two" & ASCII.LF & "one" & ASCII.LF & "three",
         "move-up must swap current line with previous line");
      Assert (Message_Text (S) = "Moved line up", "move-up message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "move-up must create one undo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Up);
      Assert (Message_Text (S) = "Already at first line", "first-line boundary message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "boundary no-op must preserve redo stack");

      Set_Caret (S, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & "three" & ASCII.LF & "two",
         "move-down must swap current line with next line");
      Assert (Message_Text (S) = "Moved line down", "move-down message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "text-changing line command after undo must clear redo stack");
   end Test_Phase381_Move_Line_Up_Down_And_Boundaries;

   procedure Test_Phase381_Empty_Buffer_No_Ops
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "");
      Set_Caret (S, 0);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "", "delete empty buffer must no-op");
      Assert (Message_Text (S) = "Nothing to delete", "empty delete message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "empty delete must create no undo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "", "duplicate empty buffer must no-op");
      Assert (Message_Text (S) = "Nothing to duplicate", "empty duplicate message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "empty duplicate must create no undo entry");
   end Test_Phase381_Empty_Buffer_No_Ops;

   procedure Test_Phase381_Delete_First_Last_And_One_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "two" & ASCII.LF & "three",
         "delete-line must delete the first logical line and following terminator");
      Assert (Message_Text (S) = "Deleted line", "first-line delete message mismatch");

      Set_Caret (S, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "two",
         "delete-line must delete the last logical line and preceding terminator");

      Editor.State.Load_Text (S, "solo");
      Editor.History.Undo_Stack.Clear;
      Set_Caret (S, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "",
         "delete-line on one-line buffer must leave an empty buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "one-line delete must create exactly one undo entry");
   end Test_Phase381_Delete_First_Last_And_One_Line;

   procedure Test_Phase381_Duplicate_Last_Line_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 4);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & "two" & ASCII.LF & "two",
         "duplicate-line must duplicate the last logical line below itself");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "duplicate last line must create one undo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & "two",
         "undo after duplicate last line must restore exact text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & "two" & ASCII.LF & "two",
         "redo after duplicate last line must restore exact text");
   end Test_Phase381_Duplicate_Last_Line_Undo_Redo;

   procedure Test_Phase381_Last_Line_Move_Down_No_Op_Preserves_Redo_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Redo  : Natural := 0;
      Before_Dirty : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Dirty := Editor.State.Is_Dirty (S);

      Set_Caret (S, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert (Message_Text (S) = "Already at last line", "last-line boundary message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "last-line boundary no-op must preserve redo stack");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "last-line boundary no-op must preserve dirty state");
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & "two",
         "last-line boundary no-op must not mutate text");
   end Test_Phase381_Last_Line_Move_Down_No_Op_Preserves_Redo_Dirty;

   procedure Test_Phase381_Clipboard_Selection_Navigation_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("kept clipboard"));
      Set_Primary_Selection (S, 0, 5);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);

      Assert
        (Editor.Clipboard.Has_Text
         and then To_String (Editor.Clipboard.Get_Text) = "kept clipboard",
         "line commands must not mutate clipboard text");
      Assert
        (not Editor.Selection.Has_Selection (S),
         "successful line command must clear/collapse active selection");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "line command edit behavior must not record navigation history");
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "alpha" & ASCII.LF & "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma",
         "line command must operate on caret line, not selected text extraction");
   end Test_Phase381_Clipboard_Selection_Navigation_Boundaries;



   procedure Test_Phase381_Input_Bridge_Routes_Line_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;

      function Ctrl_Shift (Key : Editor.Keybindings.Key_Code)
        return Editor.Keybindings.Key_Chord
      is
      begin
         return Editor.Keybindings.Key_Chord'
           (Key       => Key,
            Modifiers =>
              (Ctrl  => True,
               Shift => True,
               Alt   => False,
               Meta  => False));
      end Ctrl_Shift;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.Keybindings.Bind
        (Ctrl_Shift (Editor.Keybindings.Key_Delete),
         Editor.Commands.Command_Line_Delete);
      Editor.Keybindings.Bind
        (Ctrl_Shift (Editor.Keybindings.Key_Down),
         Editor.Commands.Command_Line_Duplicate);
      Editor.Keybindings.Bind
        (Ctrl_Shift (Editor.Keybindings.Key_Up),
         Editor.Commands.Command_Line_Move_Up);
      Editor.Keybindings.Bind
        (Ctrl_Shift (Editor.Keybindings.Key_Page_Down),
         Editor.Commands.Command_Line_Move_Down);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Set_Caret (S, 4);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord
        (Ctrl_Shift (Editor.Keybindings.Key_Delete));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Text_Buffer.UTF8_Text (After.Buffer) = "one" & ASCII.LF & "three",
         "Input_Bridge delete-line keybinding must route through Executor");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Input_Bridge delete-line route must create one undo entry");

      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.History.Undo_Stack.Clear;
      Set_Caret (S, 4);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord
        (Ctrl_Shift (Editor.Keybindings.Key_Down));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Text_Buffer.UTF8_Text (After.Buffer) =
         "one" & ASCII.LF & "two" & ASCII.LF & "two" & ASCII.LF & "three",
         "Input_Bridge duplicate-line keybinding must route through Executor");

      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.History.Undo_Stack.Clear;
      Set_Caret (S, 4);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord
        (Ctrl_Shift (Editor.Keybindings.Key_Up));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Text_Buffer.UTF8_Text (After.Buffer) =
         "two" & ASCII.LF & "one" & ASCII.LF & "three",
         "Input_Bridge move-line-up keybinding must route through Executor");

      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.History.Undo_Stack.Clear;
      Set_Caret (S, 4);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord
        (Ctrl_Shift (Editor.Keybindings.Key_Page_Down));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Text_Buffer.UTF8_Text (After.Buffer) =
         "one" & ASCII.LF & "three" & ASCII.LF & "two",
         "Input_Bridge move-line-down keybinding must route through Executor");

      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase381_Input_Bridge_Routes_Line_Commands;

   procedure Test_Phase381_Availability_Has_No_Side_Effects
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Before_Text   : Unbounded_String;
      Before_Caret  : Cursor_Index;
      Before_Dirty  : Boolean := False;
      Before_Undo   : Natural := 0;
      Before_Redo   : Natural := 0;
      Before_Message : Unbounded_String := Null_Unbounded_String;
      Availability  : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 4);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Message := To_Unbounded_String (Message_Text (S));

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Delete);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Duplicate);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Move_Up);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Move_Down);

      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "line-command availability must not mutate buffer text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "line-command availability must not move caret");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "line-command availability must not change dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "line-command availability must not mutate undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "line-command availability must not mutate redo stack");
      Assert (Message_Text (S) = To_String (Before_Message),
              "line-command availability must not emit messages");
   end Test_Phase381_Availability_Has_No_Side_Effects;


   procedure Test_Phase382_Delete_Blank_Whitespace_And_EOF_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "alpha" & ASCII.LF & "   " & ASCII.LF & ASCII.LF & "omega");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "alpha" & ASCII.LF & ASCII.LF & "omega",
         "delete-line must remove a whitespace-only line exactly");
      Assert_Caret_Row_Col (S, 1, 0, "delete whitespace-only line");
      Assert (S.Preferred_Column = 0,
              "delete-line must align preferred column with clamped caret");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "delete whitespace-only line must create one undo entry");

      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "alpha" & ASCII.LF,
         "delete-line at EOF must delete the last logical line exactly");
      Assert_Caret_Row_Col (S, 1, 0, "delete EOF line");
   end Test_Phase382_Delete_Blank_Whitespace_And_EOF_Lines;

   procedure Test_Phase382_Duplicate_Whitespace_And_Caret_Clamp
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "longer" & ASCII.LF & "  " & ASCII.LF & "x");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 9);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "longer" & ASCII.LF & "  " & ASCII.LF & "  " & ASCII.LF & "x",
         "duplicate-line must duplicate whitespace-only line exactly");
      Assert_Caret_Row_Col (S, 2, 2, "duplicate whitespace-only line");
      Assert (S.Preferred_Column = 2,
              "duplicate-line must align preferred column with duplicated line caret");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "longer" & ASCII.LF & "  " & ASCII.LF & "x",
         "undo after whitespace duplicate must restore exact text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "longer" & ASCII.LF & "  " & ASCII.LF & "  " & ASCII.LF & "x",
         "redo after whitespace duplicate must restore exact text");
   end Test_Phase382_Duplicate_Whitespace_And_Caret_Clamp;

   procedure Test_Phase382_Move_Blank_Line_And_Attached_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "aa" & ASCII.LF & ASCII.LF & "cccc");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 3);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "aa" & ASCII.LF & "cccc" & ASCII.LF,
         "move-down must swap a blank current line with the next line exactly");
      Assert_Caret_Row_Col (S, 2, 0, "move blank line down");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Set_Caret (S, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Up);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = ASCII.LF & "aa" & ASCII.LF & "cccc",
         "move-up must swap a blank current line with the previous line exactly");
      Assert_Caret_Row_Col (S, 0, 0, "move blank line up");
   end Test_Phase382_Move_Blank_Line_And_Attached_Caret;

   procedure Test_Phase382_Redo_Find_And_Boundary_No_Op_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Redo_Count : Natural := 0;
      Dirty_Before : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      S.Active_Find_Query := To_Unbounded_String ("two");
      S.Active_Find_Stale := False;
      Set_Caret (S, 0);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert (S.Active_Find_Stale,
              "successful line edit must mark active Find state stale when a query exists");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Up);
      Assert (Message_Text (S) = "Already at first line",
              "boundary move-up must report already at first line");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "boundary no-op after undo must preserve redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "boundary no-op after undo must preserve dirty state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "successful line command after undo must clear redo stack");
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "two",
         "successful delete-line after boundary no-op must still mutate active text");
   end Test_Phase382_Redo_Find_And_Boundary_No_Op_Reliability;

   procedure Test_Phase381_Trailing_Newline_Line_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 4);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & ASCII.LF & "two",
         "move-down must treat an explicit trailing newline as an empty logical line");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "trailing-newline move-down must create one undo entry when text changes");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & "two" & ASCII.LF,
         "undo must restore exact trailing-newline text");

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "one" & ASCII.LF & "two" & ASCII.LF,
         "duplicate-line must preserve explicit trailing newline representation");
   end Test_Phase381_Trailing_Newline_Line_Boundaries;



   procedure Assert_Line_Edit_Coherent
     (S                  : Editor.State.State_Type;
      Expected_Text      : String;
      Expected_Undo      : Natural;
      Expected_Redo      : Natural;
      Expected_Clipboard : String;
      Why                : String)
   is
   begin
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) = Expected_Text,
         Why & ": full logical buffer text mismatch");
      Assert
        (Editor.State.Line_Count (S) >= 1 or else Text_Buffer.Length (S.Buffer) = 0,
         Why & ": logical line index must remain valid");
      Assert
        (S.Carets.Length > 0,
         Why & ": line edit must leave a caret");
      Assert
        (Natural (S.Carets (S.Carets.First_Index).Pos) <= Text_Buffer.Length (S.Buffer),
         Why & ": caret must remain inside active buffer");
      Assert
        (not Editor.Selection.Has_Selection (S),
         Why & ": successful line edit must collapse selection");
      Assert
        (Natural (Editor.History.Undo_Stack.Length) = Expected_Undo,
         Why & ": undo stack count mismatch");
      Assert
        (Natural (Editor.History.Redo_Stack.Length) = Expected_Redo,
         Why & ": redo stack count mismatch");
      Assert
        (Editor.Clipboard.Has_Text
         and then To_String (Editor.Clipboard.Get_Text) = Expected_Clipboard,
         Why & ": clipboard must be unchanged by line edit");
   end Assert_Line_Edit_Coherent;

   procedure Test_Phase383_Delete_Duplicate_Move_Workflow_Consistency
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A" & ASCII.LF & "B" & ASCII.LF & "C");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));

      Set_Caret (S, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert_Line_Edit_Coherent
        (S, "A" & ASCII.LF & "C", 1, 0, "CLIP",
         "delete middle line workflow");
      Assert (Message_Text (S) = "Deleted line",
              "delete-line must emit one primary line message");
      Assert (Editor.State.Is_Dirty (S),
              "delete-line must dirty a clean active buffer");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "A" & ASCII.LF & "B" & ASCII.LF & "C",
              "undo after delete-line must restore exact text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "A" & ASCII.LF & "C",
              "redo after delete-line must restore exact post-edit text");

      Set_Caret (S, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert_Line_Edit_Coherent
        (S, "A" & ASCII.LF & "C" & ASCII.LF & "C", 2, 0, "CLIP",
         "duplicate last line workflow");
      Assert (Message_Text (S) = "Duplicated line",
              "duplicate-line must emit one primary line message");

      Set_Caret (S, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Up);
      Assert_Line_Edit_Coherent
        (S, "C" & ASCII.LF & "A" & ASCII.LF & "C", 3, 0, "CLIP",
         "move-up workflow");
      Assert (Message_Text (S) = "Moved line up",
              "move-up must emit one primary line message");

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert_Line_Edit_Coherent
        (S, "A" & ASCII.LF & "C" & ASCII.LF & "C", 4, 0, "CLIP",
         "move-down workflow");
      Assert (Message_Text (S) = "Moved line down",
              "move-down must emit one primary line message");
   end Test_Phase383_Delete_Duplicate_Move_Workflow_Consistency;

   procedure Test_Phase383_Line_Terminator_Matrix_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A" & ASCII.LF & "" & ASCII.LF & "   " & ASCII.LF & "C" & ASCII.LF);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 2);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "A" & ASCII.LF & ASCII.LF & ASCII.LF & "   " & ASCII.LF & "C" & ASCII.LF,
         "duplicate blank line must preserve explicit logical terminators");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "A" & ASCII.LF & ASCII.LF & "   " & ASCII.LF & "C" & ASCII.LF,
         "undo must restore exact blank/whitespace/trailing-newline fixture");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "A" & ASCII.LF & ASCII.LF & ASCII.LF & "   " & ASCII.LF & "C" & ASCII.LF,
         "redo must restore exact duplicate-blank-line fixture");

      Set_Caret (S, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "A" & ASCII.LF & ASCII.LF & "   " & ASCII.LF & ASCII.LF & "C" & ASCII.LF,
         "move-down must swap blank and whitespace-only logical lines without trimming");

      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "A" & ASCII.LF & ASCII.LF & ASCII.LF & "C" & ASCII.LF,
         "delete whitespace-only line must preserve neighboring blank terminators exactly");
   end Test_Phase383_Line_Terminator_Matrix_Undo_Redo;

   procedure Test_Phase383_Selection_Clipboard_Find_Redo_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Redo_Count : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("beta");
      S.Active_Find_Stale := False;
      S.Active_Replace_Text := To_Unbounded_String ("BETA");
      Set_Primary_Selection (S, 0, 5);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "alpha" & ASCII.LF & "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma",
         "line command must operate on caret line, not selected text");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful line command must collapse active selection");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "line command must not mutate clipboard text");
      Assert (To_String (S.Active_Find_Query) = "beta",
              "line command must not mutate Find query");
      Assert (To_String (S.Active_Replace_Text) = "BETA",
              "line command must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "text-changing line command must invalidate active Find state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Up);
      Assert (Message_Text (S) = "Already at first line",
              "boundary no-op must report only its line-edit status");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "boundary no-op must preserve redo stack after undo");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "boundary no-op must not mutate clipboard");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "alpha" & ASCII.LF & "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma",
         "redo after preserved boundary no-op must restore post-edit text");
   end Test_Phase383_Selection_Clipboard_Find_Redo_Boundaries;

   procedure Test_Phase383_Dirty_History_Clear_And_No_Op_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Dirty_Before : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 0);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert (Message_Text (S) = "Already at last line",
              "single-line move-down must be a boundary no-op");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "boundary no-op must not create undo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "boundary no-op must not dirty a clean buffer");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "",
              "delete one-line buffer must empty the active buffer");
      Assert (Editor.State.Is_Dirty (S),
              "text-changing line edit must dirty clean buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "delete one-line must create exactly one undo entry");

      Dirty_Before := Editor.State.Is_Dirty (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Edit_History_Clear);
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "history.clear after line edit must not change dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "history.clear must clear canonical undo stack");
   end Test_Phase383_Dirty_History_Clear_And_No_Op_Policy;

   procedure Test_Phase383_Availability_Projection_And_Non_Goal_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Text    : Unbounded_String;
      Before_Find    : Unbounded_String;
      Before_Replace : Unbounded_String;
      Availability   : Editor.Commands.Command_Availability;
      Id             : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Found          : Boolean := False;

      procedure Assert_Not_Exposed (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found, Name & " must not be exposed as a line-edit command");
      end Assert_Not_Exposed;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("two");
      S.Active_Replace_Text := To_Unbounded_String ("TWO");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Set_Primary_Selection (S, 0, 3);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Find := S.Active_Find_Query;
      Before_Replace := S.Active_Replace_Text;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Delete);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Duplicate);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Move_Up);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Move_Down);

      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "availability/projection must not perform line edits");
      Assert (Editor.Selection.Has_Selection (S),
              "availability/projection must not clear selection");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "availability/projection must not mutate clipboard");
      Assert (S.Active_Find_Query = Before_Find,
              "availability/projection must not mutate Find query");
      Assert (S.Active_Replace_Text = Before_Replace,
              "availability/projection must not mutate Replace text");
      Assert (not Editor.State.Is_Dirty (S),
              "availability/projection must not dirty buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "availability/projection must not create undo entries");

      Assert_Not_Exposed ("edit.line.copy");
      Assert_Not_Exposed ("edit.line.cut");
      Assert_Not_Exposed ("edit.line.paste");
      Assert_Not_Exposed ("edit.line.sort");
      Assert_Not_Exposed ("edit.line.join");
      Assert_Not_Exposed ("edit.line.split");
      Assert_Not_Exposed ("edit.line.comment");
      Assert_Not_Exposed ("edit.line.indent");
      Assert_Not_Exposed ("edit.line.outdent");
      Assert_Not_Exposed ("edit.multi-cursor.line");
   end Test_Phase383_Availability_Projection_And_Non_Goal_Surface;

   procedure Test_Phase384_Keybinding_Config_Rejects_Removed_Name_Line_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := "/tmp/editor-phase384-removed-name-line-keybindings";
      File   : Ada.Text_IO.File_Type;
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Found  : Boolean := False;
      Chord  : Editor.Keybindings.Key_Chord;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put_Line (File, "editor-keybindings-version=1");
      Ada.Text_IO.Put_Line (File, "[bindings]");
      Ada.Text_IO.Put_Line (File, "line.delete=Ctrl+Alt+L");
      Ada.Text_IO.Put_Line (File, "edit.delete-line=Ctrl+Alt+D");
      Ada.Text_IO.Put_Line (File, "edit.line.delete=Ctrl+Alt+S");
      Ada.Text_IO.Close (File);

      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert
        (Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load,
         "removed line-edit command names in keybindings must be rejected as partial load");

      Chord := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Line_Delete, Found);
      Assert
        (Found and then Editor.Keybindings.Format_Chord (Chord) = "Ctrl+Alt+S",
         "canonical line-edit keybinding must remain loadable while removed alternate names are ignored");
   end Test_Phase384_Keybinding_Config_Rejects_Removed_Name_Line_Names;

   procedure Test_Phase384_Default_Keybindings_And_Runtime_Routes_Are_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Status   : Editor.Keybindings.Binding_Result;
      Cfg      : Editor.Keybinding_Config.Keybinding_Config_Model;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert
        (Editor.Keybindings.Status (Editor.Keybindings.Validate) = Editor.Keybindings.Valid_Keybindings,
         "default keybindings must remain valid after line-edit cleanup");

      Editor.Keybinding_Config.Build_From_Runtime (Cfg);
      for I in 1 .. Editor.Keybinding_Config.Binding_Count (Cfg) loop
         declare
            Id   : constant Editor.Commands.Command_Id :=
              Editor.Keybinding_Config.Command_At (Cfg, I);
            Name : constant String := Editor.Commands.Stable_Command_Name (Id);
         begin
            Assert
              (Name /= "line.delete"
               and then Name /= "line.duplicate"
               and then Name /= "line.move-up"
               and then Name /= "line.move-down"
               and then Name /= "edit.delete-line"
               and then Name /= "edit.duplicate-line"
               and then Name /= "edit.move-line-up"
               and then Name /= "edit.move-line-down",
               "runtime/default keybindings must not persist removed line-edit command names");
         end;
      end loop;

      Editor.Keybindings.Bind
        ((Key       => Editor.Keybindings.Key_Delete,
          Modifiers => (Ctrl => True, Shift => True, Alt => True, Meta => False)),
         Editor.Commands.Command_Line_Delete);
      Status := Editor.Keybindings.Resolve
        ((Key       => Editor.Keybindings.Key_Delete,
          Modifiers => (Ctrl => True, Shift => True, Alt => True, Meta => False)),
         Resolved);
      Assert
        (Status = Editor.Keybindings.Bound_Command
         and then Resolved = Editor.Commands.Command_Line_Delete,
         "runtime keybinding resolution must target the canonical delete-line command id");

      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase384_Default_Keybindings_And_Runtime_Routes_Are_Canonical;


   procedure Test_Phase385_Indent_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      pragma Unreferenced (Id);

      procedure Assert_Not_Exposed (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found, Name & " must not be exposed in Phase 385");
      end Assert_Not_Exposed;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Indent_Increase) = "edit.indent.increase",
         "indent increase stable name mismatch");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Indent_Decrease) = "edit.indent.decrease",
         "indent decrease stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Indent_Increase).Category =
         Editor.Commands.Edit_Category,
         "indent increase must be an Edit command");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Indent_Decrease).Category =
         Editor.Commands.Edit_Category,
         "indent decrease must be an Edit command");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Indent_Increase),
         "indent increase must be bindable");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Indent_Decrease),
         "indent decrease must be bindable");
      Assert
        (Editor.Commands.Visible_In_Command_Palette
           (Editor.Commands.Command_Indent_Increase),
         "indent increase must be command-palette visible");
      Assert
        (Editor.Commands.Visible_In_Command_Palette
           (Editor.Commands.Command_Indent_Decrease),
         "indent decrease must be command-palette visible");
      Assert
        (Editor.Commands.Is_Text_Editing_Command
           (Editor.Commands.Command_Indent_Increase),
         "indent increase must be classified as a text edit");
      Assert
        (Editor.Commands.Is_Text_Editing_Command
           (Editor.Commands.Command_Indent_Decrease),
         "indent decrease must be classified as a text edit");

      Assert_Not_Exposed ("edit.indent.selection");
      Assert_Not_Exposed ("edit.outdent.selection");
      Assert_Not_Exposed ("edit.indent.block");
      Assert_Not_Exposed ("edit.indent.smart");
      Assert_Not_Exposed ("edit.indent.auto");
      Assert_Not_Exposed ("edit.format.document");
      Assert_Not_Exposed ("edit.format.selection");
      Assert_Not_Exposed ("edit.tabs.convert-to-spaces");
      Assert_Not_Exposed ("edit.tabs.convert-to-tabs");
   end Test_Phase385_Indent_Command_Descriptors;


   procedure Test_Phase385_Indent_Increase_Undo_Redo_And_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 5);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);

      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  two" & ASCII.LF & "three",
         "indent increase must insert the two-space indentation unit at line start");
      Assert (Message_Text (S) = "Indented line",
              "indent increase message mismatch");
      Assert_Caret_Row_Col (S, 1, 3,
                            "indent increase must shift caret right by unit width");
      Assert (Editor.State.Is_Dirty (S),
              "indent increase must dirty a clean buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "indent increase must create exactly one undo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "two" & ASCII.LF & "three",
         "undo after indent increase must restore exact text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  two" & ASCII.LF & "three",
         "redo after indent increase must restore exact indented text");
   end Test_Phase385_Indent_Increase_Undo_Redo_And_Caret;


   procedure Test_Phase385_Indent_Increase_Blank_Whitespace_And_Empty_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & ASCII.LF & " " & ASCII.LF & "omega");
      Editor.State.Set_Dirty (S, False);

      Set_Caret (S, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "  alpha" & ASCII.LF & ASCII.LF & " " & ASCII.LF & "omega",
         "indent increase must indent the first logical line");

      Set_Caret (S, 8);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "  alpha" & ASCII.LF & "  " & ASCII.LF & " " & ASCII.LF & "omega",
         "indent increase must indent a blank logical line");

      Set_Caret (S, 12);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "  alpha" & ASCII.LF & "  " & ASCII.LF & "   " & ASCII.LF & "omega",
         "indent increase must indent a whitespace-only logical line");

      Set_Caret (S, 15);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "  alpha" & ASCII.LF & "  " & ASCII.LF & "   " & ASCII.LF & "  omega",
         "indent increase must indent the last logical line");

      Editor.State.Load_Text (S, "");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "",
              "empty buffer indent increase must not mutate text");
      Assert (Message_Text (S) = "Nothing to indent",
              "empty buffer indent increase no-op message mismatch");
      Assert (not Editor.State.Is_Dirty (S),
              "empty buffer indent increase must leave clean state unchanged");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "empty buffer indent increase must not create an undo entry");
   end Test_Phase385_Indent_Increase_Blank_Whitespace_And_Empty_Buffer;


   procedure Test_Phase385_Outdent_Policy_Undo_Redo_And_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Dirty_Before : Boolean := False;
      Redo_Count   : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "  full" & ASCII.LF & " partial" & ASCII.LF &
            ASCII.HT & "tabbed" & ASCII.LF & "plain");
      Editor.State.Set_Dirty (S, False);

      Set_Caret (S, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "full" & ASCII.LF & " partial" & ASCII.LF & ASCII.HT & "tabbed" & ASCII.LF & "plain",
         "outdent must remove one full two-space indentation unit");
      Assert (Message_Text (S) = "Outdented line",
              "outdent success message mismatch");
      Assert_Caret_Row_Col (S, 0, 2,
                            "outdent must shift caret left by removed prefix");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "outdent text change must create one undo entry");

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "full" & ASCII.LF & "partial" & ASCII.LF & ASCII.HT & "tabbed" & ASCII.LF & "plain",
         "outdent must remove partial spaces fewer than one unit");

      Set_Caret (S, 14);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "full" & ASCII.LF & "partial" & ASCII.LF & "tabbed" & ASCII.LF & "plain",
         "outdent must remove one leading tab literally");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "full" & ASCII.LF & "partial" & ASCII.LF & ASCII.HT & "tabbed" & ASCII.LF & "plain",
         "undo after outdent must restore exact previous text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "full" & ASCII.LF & "partial" & ASCII.LF & "tabbed" & ASCII.LF & "plain",
         "redo after outdent must restore exact later text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      S.Active_Find_Query := To_Unbounded_String ("plain");
      S.Active_Find_Stale := False;
      Set_Primary_Selection (S, 21, 23);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert (Message_Text (S) = "Nothing to outdent",
              "unindented outdent must report deterministic no-op");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "no-op outdent after undo must preserve redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "no-op outdent must leave dirty state unchanged");
      Assert (not S.Active_Find_Stale,
              "no-op outdent must not invalidate Find/Replace state");
      Assert (Editor.Selection.Has_Selection (S),
              "no-op outdent must preserve an already valid active selection");

      Editor.State.Load_Text (S, "");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "",
              "empty buffer outdent must not mutate text");
      Assert (Message_Text (S) = "Nothing to outdent",
              "empty buffer outdent no-op message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "empty buffer outdent must not create an undo entry");
   end Test_Phase385_Outdent_Policy_Undo_Redo_And_No_Op;


   procedure Test_Phase385_Indent_Selection_Clipboard_Find_And_Navigation_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("beta");
      S.Active_Find_Stale := False;
      Set_Primary_Selection (S, 8, 6);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);

      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "alpha" & ASCII.LF & "  beta" & ASCII.LF & "gamma",
         "indent command must operate on caret line only, not selected lines");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful indent command must clear/collapse active selection");
      Assert
        (Editor.Clipboard.Has_Text
         and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
         "indent command must not mutate clipboard text");
      Assert (To_String (S.Active_Find_Query) = "beta",
              "indent command must not mutate Find query");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "text-changing indent command must invalidate active Find matches");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "indent command must not record navigation history");
   end Test_Phase385_Indent_Selection_Clipboard_Find_And_Navigation_Boundaries;


   procedure Test_Phase385_Indent_Input_Bridge_And_Availability_Side_Effects
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      After        : Editor.State.State_Type;
      Before_Text  : Unbounded_String;
      Availability  : Editor.Commands.Command_Availability;

      function Ctrl_Alt (Key : Editor.Keybindings.Key_Code)
        return Editor.Keybindings.Key_Chord
      is
      begin
         return Editor.Keybindings.Key_Chord'
           (Key       => Key,
            Modifiers =>
              (Ctrl  => True,
               Shift => False,
               Alt   => True,
               Meta  => False));
      end Ctrl_Alt;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "line");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 2);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Indent_Increase);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Indent_Decrease);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "indent availability must not mutate text");
      Assert_Caret_Row_Col (S, 0, 2,
                            "indent availability must not move caret");
      Assert (not Editor.State.Is_Dirty (S),
              "indent availability must not dirty buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "indent availability must not create undo entries");

      Editor.Keybindings.Bind
        (Ctrl_Alt (Editor.Keybindings.Key_Right),
         Editor.Commands.Command_Indent_Increase);
      Editor.Keybindings.Bind
        (Ctrl_Alt (Editor.Keybindings.Key_Left),
         Editor.Commands.Command_Indent_Decrease);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord
        (Ctrl_Alt (Editor.Keybindings.Key_Right));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Text_Buffer.UTF8_Text (After.Buffer) = "  line",
              "Input_Bridge indent increase binding must route through Executor");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle_Key_Chord
        (Ctrl_Alt (Editor.Keybindings.Key_Left));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Text_Buffer.UTF8_Text (After.Buffer) = "line",
              "Input_Bridge indent decrease binding must route through Executor");

      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase385_Indent_Input_Bridge_And_Availability_Side_Effects;


   procedure Test_Phase386_Leading_Whitespace_Outdent_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Assert_Outdent
        (Before_Text : String;
         After_Text  : String;
         Why         : String)
      is
         S : Editor.State.State_Type;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Before_Text);
         Editor.State.Set_Dirty (S, False);
         Set_Caret (S, 0);

         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Indent_Decrease);

         Assert (Text_Buffer.UTF8_Text (S.Buffer) = After_Text, Why);
         if Before_Text = After_Text then
            Assert (Message_Text (S) = "Nothing to outdent",
                    Why & ": no-op message mismatch");
            Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
                    Why & ": no-op must not create undo entry");
            Assert (not Editor.State.Is_Dirty (S),
                    Why & ": no-op must not dirty buffer");
         else
            Assert (Message_Text (S) = "Outdented line",
                    Why & ": success message mismatch");
            Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                    Why & ": text change must create one undo entry");
            Assert (Editor.State.Is_Dirty (S),
                    Why & ": text change must dirty clean buffer");

            Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
            Assert (Text_Buffer.UTF8_Text (S.Buffer) = Before_Text,
                    Why & ": undo must restore exact text");
            Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
            Assert (Text_Buffer.UTF8_Text (S.Buffer) = After_Text,
                    Why & ": redo must restore exact outdented text");
         end if;
      end Assert_Outdent;
   begin
      Assert_Outdent ("Alpha", "Alpha", "unindented line must no-op");
      Assert_Outdent (" Alpha", "Alpha", "one leading space must be removed");
      Assert_Outdent ("  Alpha", "Alpha", "one full two-space unit must be removed");
      Assert_Outdent ("   Alpha", " Alpha", "three leading spaces must remove one unit");
      Assert_Outdent ("    Alpha", "  Alpha", "four leading spaces must remove one unit");
      Assert_Outdent (String'(1 => ASCII.HT) & "Alpha", "Alpha",
                      "one leading tab must be removed literally");
      Assert_Outdent (String'(1 => ASCII.HT) & "  Alpha", "  Alpha",
                      "tab plus spaces must remove only the tab");
      Assert_Outdent (" " & String'(1 => ASCII.HT) & "Alpha",
                      String'(1 => ASCII.HT) & "Alpha",
                      "space plus tab must remove only the partial spaces");
      Assert_Outdent ("", "", "empty buffer must no-op");
      Assert_Outdent (" ", "", "one-space blank line must be emptied");
      Assert_Outdent ("  ", "", "two-space blank line must remove one unit");
      Assert_Outdent ("   ", " ", "three-space blank line must remove one unit");
   end Test_Phase386_Leading_Whitespace_Outdent_Matrix;


   procedure Test_Phase386_Indent_Exact_Unit_And_Line_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one" & ASCII.LF & String'(1 => ASCII.HT) & "Two" & ASCII.LF &
            "   " & ASCII.LF & "last");
      Editor.State.Set_Dirty (S, False);

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Increase);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  " & String'(1 => ASCII.HT) & "Two" &
         ASCII.LF & "   " & ASCII.LF & "last",
         "indent must insert exactly the two-space unit at current line start");
      Assert_Caret_Row_Col
        (S, 1, 4,
         "indent must keep caret on same logical line and shift right by unit width");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "indent must create one undo entry for a text change");

      Set_Caret (S, 12);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Increase);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  " & String'(1 => ASCII.HT) & "Two" &
         ASCII.LF & "     " & ASCII.LF & "last",
         "indent must mutate only the whitespace-only caret line");
      Assert_Caret_Row_Col
        (S, 2, 3,
         "indent on whitespace-only line must leave a valid shifted caret");

      Set_Caret (S, 19);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Increase);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  " & String'(1 => ASCII.HT) & "Two" &
         ASCII.LF & "     " & ASCII.LF & "  last",
         "indent must mutate only the last logical line and preserve terminators");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  " & String'(1 => ASCII.HT) & "Two" &
         ASCII.LF & "     " & ASCII.LF & "last",
         "undo after line-boundary indent must restore exact previous text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  " & String'(1 => ASCII.HT) & "Two" &
         ASCII.LF & "     " & ASCII.LF & "  last",
         "redo after line-boundary indent must restore exact later text");
   end Test_Phase386_Indent_Exact_Unit_And_Line_Boundaries;


   procedure Test_Phase386_Redo_Find_Selection_Clipboard_And_Navigation_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Before_Redo   : Natural := 0;
      Before_Back   : Natural := 0;
      Before_Fwd    : Natural := 0;
      Dirty_Before  : Boolean := False;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Find_Stale := False;
      Set_Primary_Selection (S, 0, 4);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Increase);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "  Alpha" & ASCII.LF & "Beta",
              "indent must use current in-memory text and current logical line");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful indentation must collapse stale active selection");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "text-changing indentation must invalidate active Find matches");
      Assert
        (Editor.Clipboard.Has_Text
         and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
         "indentation must not mutate clipboard state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      S.Active_Find_Query := To_Unbounded_String ("Alpha");
      S.Active_Find_Stale := False;
      Set_Primary_Selection (S, 4, 0);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Decrease);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "Beta",
              "no-op outdent after undo must leave text unchanged");
      Assert (Message_Text (S) = "Nothing to outdent",
              "no-op outdent after undo message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "no-op outdent after undo must preserve redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "no-op outdent after undo must preserve dirty state");
      Assert (not S.Active_Find_Stale,
              "no-op outdent must not invalidate Find/Replace");
      Assert (Editor.Selection.Has_Selection (S),
              "no-op outdent must preserve a valid selection");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "no-op outdent must not record navigation history");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Increase);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "text-changing indent after undo must clear redo stack");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "text-changing indent after preserved redo must invalidate Find once");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "text-changing indent must not record navigation history");
   end Test_Phase386_Redo_Find_Selection_Clipboard_And_Navigation_Reliability;


   procedure Test_Phase386_Line_Edit_Coexistence_And_Current_Line_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Selection (S, 0, 4);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Increase);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  two" & ASCII.LF & "three",
         "indent must operate only on caret line, not all selected lines");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Duplicate);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  two" & ASCII.LF & "  two" & ASCII.LF & "three",
         "duplicate-line after indent must reuse canonical logical-line boundaries");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Decrease);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  two" & ASCII.LF & "two" & ASCII.LF & "three",
         "outdent after duplicate-line must mutate only the current logical line");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Move_Down);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  two" & ASCII.LF & "three" & ASCII.LF & "two",
         "move-down after outdent must preserve exact line text and terminators");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "one" & ASCII.LF & "  two" & ASCII.LF & "  two" & ASCII.LF & "three",
         "mixed line-edit and indentation undo ordering must be coherent");
   end Test_Phase386_Line_Edit_Coexistence_And_Current_Line_Only;


   procedure Test_Phase386_No_Caret_Render_Persistence_And_Non_Goals
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Snap           : Editor.Render_Model.Render_Snapshot;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      A              : Editor.Commands.Command_Availability;
      Found          : Boolean := True;
      Id             : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 1);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Increase);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "  Alpha" & ASCII.LF & "Beta",
              "setup indent must change text before render/persistence checks");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot after indentation must report current buffer length");
      Assert (Snap.Caret_Count > 0,
              "render snapshot after indentation must expose a valid caret");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "  Alpha" & ASCII.LF & "Beta",
              "render snapshot must not perform or normalize indentation by mutation");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "render snapshot must not mutate undo history");
      Assert (Editor.State.Is_Dirty (S),
              "render snapshot must not clear dirty state");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert (Index (Summary, "Indent") = 0,
              "workspace snapshot must not persist indentation command status/state");
      Assert (Index (Summary, "Outdent") = 0,
              "workspace snapshot must not persist outdent command status/state");
      Assert (Index (Summary, "tab width") = 0,
              "workspace snapshot must not persist tab-width indentation policy");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.indent.selection", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "selected-line indentation command must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.format.document", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "format-document command must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.tabs.convert-to-spaces", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "tabs-to-spaces command must remain absent");

      S.Carets.Clear;
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Indent_Increase);
      Assert (A.Status = Editor.Commands.Command_Unavailable
              and then Editor.Commands.Unavailable_Reason (A) = "No caret location",
              "indent increase availability without caret must be unavailable without mutation");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Indent_Decrease);
      Assert (A.Status = Editor.Commands.Command_Unavailable
              and then Editor.Commands.Unavailable_Reason (A) = "No caret location",
              "indent decrease availability without caret must be unavailable without mutation");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "  Alpha" & ASCII.LF & "Beta",
              "no-caret availability must not mutate text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "no-caret availability must not mutate undo history");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Increase);
      Assert (Message_Text (S) = "No caret location",
              "indent increase without caret must report canonical no-caret message");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "  Alpha" & ASCII.LF & "Beta",
              "failed no-caret indent must not mutate text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "failed no-caret indent must not create an undo entry");
   end Test_Phase386_No_Caret_Render_Persistence_And_Non_Goals;


   procedure Test_Phase387_Indent_Increase_Workflow_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Assert_Indent
        (Before_Text  : String;
         Caret_Pos    : Cursor_Index;
         After_Text   : String;
         Expected_Row : Natural;
         Expected_Col : Natural;
         Why          : String)
      is
         S             : Editor.State.State_Type;
         Before_Back   : Natural := 0;
         Before_Fwd    : Natural := 0;
         Before_Msgs   : Natural := 0;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Before_Text);
         Editor.State.Set_Dirty (S, False);
         Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
         S.Active_Find_Query := To_Unbounded_String ("Alpha");
         S.Active_Find_Stale := False;
         Set_Caret (S, Caret_Pos);
         Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
         Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
         Before_Msgs := Natural (Editor.Messages.Count (S.Messages));

         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Indent_Increase);

         Assert (Text_Buffer.UTF8_Text (S.Buffer) = After_Text, Why);
         Assert (Text_Buffer.Line_Count (S.Buffer) =
                 Text_Buffer.Line_Count (S.Buffer),
                 Why & ": buffer line model must remain valid");
         Assert_Caret_Row_Col (S, Expected_Row, Expected_Col,
                               Why & ": caret policy mismatch");
         Assert (Message_Text (S) = "Indented line",
                 Why & ": success message mismatch");
         Assert (Natural (Editor.Messages.Count (S.Messages)) = Before_Msgs + 1,
                 Why & ": indentation must emit one primary message");
         Assert (Editor.State.Is_Dirty (S),
                 Why & ": text-changing indent must dirty a clean buffer");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": text-changing indent must create one undo entry");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": text-changing indent must clear redo stack");
         Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
                 Why & ": text-changing indent must invalidate Find matches");
         Assert (Editor.Clipboard.Has_Text
                 and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
                 Why & ": indent must not mutate clipboard");
         Assert_Navigation_Counts
           (S, Before_Back, Before_Fwd,
            Why & ": indent must not record navigation history");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert (Text_Buffer.UTF8_Text (S.Buffer) = Before_Text,
                 Why & ": undo must restore exact pre-indent text");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert (Text_Buffer.UTF8_Text (S.Buffer) = After_Text,
                 Why & ": redo must restore exact post-indent text");
      end Assert_Indent;

      S              : Editor.State.State_Type;
      Before_Redo    : Natural := 0;
      Before_Dirty   : Boolean := False;
      Before_Text    : Unbounded_String;
   begin
      Assert_Indent ("Alpha", 0, "  Alpha", 0, 2,
                     "single non-empty line increase-indent workflow");
      Assert_Indent (" Alpha", 1, "   Alpha", 0, 3,
                     "already space-indented line increase-indent workflow");
      Assert_Indent (String'(1 => ASCII.HT) & "Alpha", 1,
                     "  " & String'(1 => ASCII.HT) & "Alpha", 0, 3,
                     "tab-leading line increase-indent workflow");
      Assert_Indent ("A" & ASCII.LF & "B" & ASCII.LF & "C", 2,
                     "A" & ASCII.LF & "  B" & ASCII.LF & "C", 1, 2,
                     "middle logical line increase-indent workflow");
      Assert_Indent ("A" & ASCII.LF & ASCII.LF & "C", 2,
                     "A" & ASCII.LF & "  " & ASCII.LF & "C", 1, 2,
                     "blank logical line increase-indent workflow");
      Assert_Indent ("A" & ASCII.LF & " " & ASCII.LF & "C", 2,
                     "A" & ASCII.LF & "   " & ASCII.LF & "C", 1, 3,
                     "whitespace-only logical line increase-indent workflow");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 0);
      S.Active_Find_Query := To_Unbounded_String ("anything");
      S.Active_Find_Stale := False;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "",
              "empty buffer indent-increase must leave text unchanged");
      Assert (Message_Text (S) = "Nothing to indent",
              "empty buffer indent-increase no-op message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "empty buffer indent-increase must not create undo history");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "empty buffer indent-increase must preserve redo history");
      Assert (not Editor.State.Is_Dirty (S),
              "empty buffer indent-increase must not dirty buffer");
      Assert (not S.Active_Find_Stale,
              "empty buffer indent-increase must not invalidate Find state");

      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) /= To_String (Before_Text),
              "text-changing indent after undo must produce a new post-undo state");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "text-changing indent after undo must clear redo stack");
      Assert (Before_Redo > 0 and then Editor.State.Is_Dirty (S) /= Before_Dirty,
              "redo invalidation setup must observe the undo boundary");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Message_Text (S) = "No edits to redo",
              "redo after text-changing indent must report no redo entry");
   end Test_Phase387_Indent_Increase_Workflow_Matrix;


   procedure Test_Phase387_Outdent_Workflow_And_Whitespace_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Assert_Outdent
        (Before_Text  : String;
         After_Text   : String;
         Expected_Msg  : String;
         Why           : String)
      is
         S             : Editor.State.State_Type;
         Before_Back   : Natural := 0;
         Before_Fwd    : Natural := 0;
         Before_Redo   : Natural := 0;
         Before_Dirty  : Boolean := False;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Before_Text);
         Editor.State.Set_Dirty (S, False);
         Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
         S.Active_Find_Query := To_Unbounded_String ("Alpha");
         S.Active_Find_Stale := False;
         Set_Caret (S, 0);
         Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
         Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
         Before_Redo := Natural (Editor.History.Redo_Stack.Length);
         Before_Dirty := Editor.State.Is_Dirty (S);

         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Indent_Decrease);

         Assert (Text_Buffer.UTF8_Text (S.Buffer) = After_Text, Why);
         Assert (Message_Text (S) = Expected_Msg,
                 Why & ": message mismatch");
         Assert (Editor.Clipboard.Has_Text
                 and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
                 Why & ": outdent must not mutate clipboard");
         Assert_Navigation_Counts
           (S, Before_Back, Before_Fwd,
            Why & ": outdent must not record navigation history");

         if Before_Text = After_Text then
            Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
                    Why & ": no-op outdent must not create undo history");
            Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
                    Why & ": no-op outdent must preserve redo history");
            Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
                    Why & ": no-op outdent must preserve dirty state");
            Assert (not S.Active_Find_Stale,
                    Why & ": no-op outdent must not invalidate Find state");
         else
            Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                    Why & ": text-changing outdent must create one undo entry");
            Assert (Editor.State.Is_Dirty (S),
                    Why & ": text-changing outdent must dirty a clean buffer");
            Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
                    Why & ": text-changing outdent must invalidate Find matches");
            Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
            Assert (Text_Buffer.UTF8_Text (S.Buffer) = Before_Text,
                    Why & ": undo must restore exact pre-outdent text");
            Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
            Assert (Text_Buffer.UTF8_Text (S.Buffer) = After_Text,
                    Why & ": redo must restore exact post-outdent text");
         end if;
      end Assert_Outdent;
   begin
      Assert_Outdent ("Alpha", "Alpha", "Nothing to outdent",
                      "unindented line outdent workflow");
      Assert_Outdent (" Alpha", "Alpha", "Outdented line",
                      "one leading space outdent workflow");
      Assert_Outdent ("  Alpha", "Alpha", "Outdented line",
                      "one full two-space unit outdent workflow");
      Assert_Outdent ("   Alpha", " Alpha", "Outdented line",
                      "three leading spaces outdent workflow");
      Assert_Outdent ("    Alpha", "  Alpha", "Outdented line",
                      "two indentation units outdent workflow");
      Assert_Outdent (String'(1 => ASCII.HT) & "Alpha", "Alpha", "Outdented line",
                      "leading tab outdent workflow");
      Assert_Outdent (String'(1 => ASCII.HT) & "  Alpha", "  Alpha", "Outdented line",
                      "tab followed by spaces outdent workflow");
      Assert_Outdent (" " & String'(1 => ASCII.HT) & "Alpha",
                      String'(1 => ASCII.HT) & "Alpha", "Outdented line",
                      "space followed by tab outdent workflow");
      Assert_Outdent ("", "", "Nothing to outdent",
                      "empty buffer outdent workflow");
      Assert_Outdent (" ", "", "Outdented line",
                      "single whitespace-only line outdent workflow");
      Assert_Outdent ("  ", "", "Outdented line",
                      "two-space whitespace-only line outdent workflow");
      Assert_Outdent ("   ", " ", "Outdented line",
                      "three-space whitespace-only line outdent workflow");
   end Test_Phase387_Outdent_Workflow_And_Whitespace_Matrix;


   procedure Test_Phase387_Selection_Clipboard_Line_Edit_Integration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Assert (Editor.Selection.Has_Selection (S),
              "select-all setup must create a canonical selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "selection commands must not create undo entries");
      Set_Primary_Selection (S, 0, 5);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "one" & ASCII.LF & "  two" & ASCII.LF & "three",
              "indent after selection workflow must mutate only caret line");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful indentation must collapse selection before clipboard use");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "indent after selection must not mutate clipboard");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "one" & ASCII.LF & "two" & ASCII.LF & "three",
              "undo after selection-indent workflow must restore text");

      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "one" & ASCII.LF & "two" & ASCII.LF & "three",
              "no-op outdent after current-word selection must not mutate text");
      Assert (Editor.Selection.Has_Selection (S),
              "no-op outdent must preserve valid current-word selection");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "two",
              "copy after no-op outdent must consume canonical preserved selection");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "one" & ASCII.LF & "two" & ASCII.LF & "two" & ASCII.LF & "three",
              "duplicate-line after selection/copy must use canonical logical line boundaries");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "one" & ASCII.LF & "two" & ASCII.LF & "  two" & ASCII.LF & "three",
              "indent after duplicate-line must use post-line-edit current line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Assert (Editor.Clipboard.Has_Text,
              "cut after mixed indentation workflow must follow clipboard policy only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert (Message_Text (S) = "Nothing to outdent" or else
              Message_Text (S) = "Outdented line",
              "post-cut outdent must produce a deterministic indentation message");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert (Natural (Editor.History.Undo_Stack.Length) > 0,
              "mixed selection/clipboard/line-edit/indent workflow must remain undoable");
   end Test_Phase387_Selection_Clipboard_Line_Edit_Integration;


   procedure Test_Phase387_Render_Availability_And_Persistence_Are_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Snap           : Editor.Render_Model.Render_Snapshot;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Before_Text    : Unbounded_String;
      Before_Caret   : Cursor_Index := 0;
      Before_Dirty   : Boolean := False;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      A              : Editor.Commands.Command_Availability;
      pragma Unreferenced (A);
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "Alpha" & ASCII.LF & "  Beta" & ASCII.LF & String'(1 => ASCII.HT) & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Find_Stale := False;
      S.Active_Replace_Prompt := True;
      S.Active_Replace_Text := To_Unbounded_String ("REPL");
      Set_Primary_Selection (S, 0, 5);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Indent_Increase);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Indent_Decrease);
      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));

      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot must derive length from canonical buffer text");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "render/availability/workspace snapshot must not mutate buffer text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "render/availability/workspace snapshot must not move caret");
      Assert (Editor.Selection.Has_Selection (S),
              "render/availability/workspace snapshot must not clear selection");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "render/availability/workspace snapshot must not mutate dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "render/availability/workspace snapshot must not mutate undo/redo stacks");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "render/availability/workspace snapshot must not mutate clipboard");
      Assert (To_String (S.Active_Find_Query) = "Beta"
              and then not S.Active_Find_Stale
              and then S.Active_Replace_Prompt
              and then To_String (S.Active_Replace_Text) = "REPL",
              "render/availability/workspace snapshot must not mutate Find/Replace state");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "render/availability/workspace snapshot must not mutate navigation history");
      Assert (Index (Summary, "Indent") = 0
              and then Index (Summary, "Outdent") = 0
              and then Index (Summary, "indentation unit") = 0
              and then Index (Summary, "tab width") = 0,
              "workspace persistence must exclude indentation transient state and settings");
   end Test_Phase387_Render_Availability_And_Persistence_Are_Read_Only;
procedure Test_Phase389_Line_Comment_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      pragma Unreferenced (Id);

      procedure Assert_Not_Exposed (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found, Name & " must not be exposed in Phase 389");
      end Assert_Not_Exposed;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Comment_Line) = "edit.comment.line",
         "comment-line stable name mismatch");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Uncomment_Line) = "edit.uncomment.line",
         "uncomment-line stable name mismatch");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Toggle_Line_Comment) = "edit.comment.toggle-line",
         "toggle-line-comment stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Comment_Line).Category =
         Editor.Commands.Edit_Category,
         "comment-line must be an Edit command");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Uncomment_Line).Category =
         Editor.Commands.Edit_Category,
         "uncomment-line must be an Edit command");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Toggle_Line_Comment).Category =
         Editor.Commands.Edit_Category,
         "toggle-line-comment must be an Edit command");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Comment_Line),
         "comment-line must be bindable");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Uncomment_Line),
         "uncomment-line must be bindable");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Toggle_Line_Comment),
         "toggle-line-comment must be bindable");
      Assert
        (Editor.Commands.Visible_In_Command_Palette
           (Editor.Commands.Command_Comment_Line),
         "comment-line must be command-palette visible");
      Assert
        (Editor.Commands.Visible_In_Command_Palette
           (Editor.Commands.Command_Uncomment_Line),
         "uncomment-line must be command-palette visible");
      Assert
        (Editor.Commands.Visible_In_Command_Palette
           (Editor.Commands.Command_Toggle_Line_Comment),
         "toggle-line-comment must be command-palette visible");
      Assert
        (Editor.Commands.Is_Text_Editing_Command
           (Editor.Commands.Command_Comment_Line),
         "comment-line must be classified as text editing");
      Assert
        (Editor.Commands.Is_Text_Editing_Command
           (Editor.Commands.Command_Uncomment_Line),
         "uncomment-line must be classified as text editing");
      Assert
        (Editor.Commands.Is_Text_Editing_Command
           (Editor.Commands.Command_Toggle_Line_Comment),
         "toggle-line-comment must be classified as text editing");

      Assert_Not_Exposed ("edit.comment.selection");
      Assert_Not_Exposed ("edit.uncomment.selection");
      Assert_Not_Exposed ("edit.comment.block");
      Assert_Not_Exposed ("edit.comment.toggle-block");
      Assert_Not_Exposed ("edit.comment.smart");
      Assert_Not_Exposed ("edit.comment.language-aware");
      Assert_Not_Exposed ("edit.comment.document");
      Assert_Not_Exposed ("edit.comment.region");
      Assert_Not_Exposed ("edit.comment.format");
   end Test_Phase389_Line_Comment_Command_Descriptors;


   procedure Test_Phase389_Comment_Line_Prefix_Matrix_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "Alpha" & ASCII.LF & "  Beta" & ASCII.LF &
            String'(1 => ASCII.HT) & "Gamma" & ASCII.LF & "  ");
      Editor.State.Set_Dirty (S, False);

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "-- Alpha" & ASCII.LF & "  Beta" & ASCII.LF &
         String'(1 => ASCII.HT) & "Gamma" & ASCII.LF & "  ",
         "comment-line must insert marker at line start without indentation");
      Assert (Message_Text (S) = "Commented line", "comment-line message mismatch");
      Assert_Caret_Row_Col (S, 0, 5, "comment-line caret shift after marker insert");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "comment-line must create one undo entry");
      Assert (Editor.State.Is_Dirty (S), "comment-line must dirty a clean buffer");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "  Beta" & ASCII.LF &
         String'(1 => ASCII.HT) & "Gamma" & ASCII.LF & "  ",
         "undo after comment-line must restore exact text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "-- Alpha" & ASCII.LF & "  Beta" & ASCII.LF &
         String'(1 => ASCII.HT) & "Gamma" & ASCII.LF & "  ",
         "redo after comment-line must restore exact commented text");

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 3)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "-- Alpha" & ASCII.LF & "  -- Beta" & ASCII.LF &
         String'(1 => ASCII.HT) & "Gamma" & ASCII.LF & "  ",
         "comment-line must insert marker after leading spaces");

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 2, 1)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "-- Alpha" & ASCII.LF & "  -- Beta" & ASCII.LF &
         String'(1 => ASCII.HT) & "-- Gamma" & ASCII.LF & "  ",
         "comment-line must insert marker after leading tab");

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 3, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "-- Alpha" & ASCII.LF & "  -- Beta" & ASCII.LF &
         String'(1 => ASCII.HT) & "-- Gamma" & ASCII.LF & "  -- ",
         "comment-line must comment whitespace-only logical lines");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (S) = "Line already commented",
              "already-commented line must report deterministic no-op");
   end Test_Phase389_Comment_Line_Prefix_Matrix_Undo_Redo;


   procedure Test_Phase389_Uncomment_And_Toggle_Policies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "-- Alpha" & ASCII.LF & "--Beta" & ASCII.LF &
            "  -- Gamma" & ASCII.LF & "  --Delta" & ASCII.LF &
            "Alpha -- note" & ASCII.LF & "Plain");
      Editor.State.Set_Dirty (S, False);

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 4)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "--Beta" & ASCII.LF &
         "  -- Gamma" & ASCII.LF & "  --Delta" & ASCII.LF &
         "Alpha -- note" & ASCII.LF & "Plain",
         "uncomment-line must remove canonical marker with trailing space");
      Assert (Message_Text (S) = "Uncommented line", "uncomment message mismatch");
      Assert_Caret_Row_Col (S, 0, 1, "uncomment-line must shift caret left");

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 3)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "Beta" & ASCII.LF &
         "  -- Gamma" & ASCII.LF & "  --Delta" & ASCII.LF &
         "Alpha -- note" & ASCII.LF & "Plain",
         "uncomment-line must remove marker without trailing space");

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 4, 8)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Message_Text (S) = "Nothing to uncomment",
              "internal marker must not be removed");
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "Beta" & ASCII.LF &
         "  -- Gamma" & ASCII.LF & "  --Delta" & ASCII.LF &
         "Alpha -- note" & ASCII.LF & "Plain",
         "internal comment marker no-op must preserve exact text");

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 5, 1)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "Beta" & ASCII.LF &
         "  -- Gamma" & ASCII.LF & "  --Delta" & ASCII.LF &
         "Alpha -- note" & ASCII.LF & "-- Plain",
         "toggle-line must comment an uncommented caret line");
      Assert (Message_Text (S) = "Commented line",
              "toggle comment operation-specific message mismatch");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "Beta" & ASCII.LF &
         "  -- Gamma" & ASCII.LF & "  --Delta" & ASCII.LF &
         "Alpha -- note" & ASCII.LF & "Plain",
         "toggle-line must uncomment a commented caret line");
      Assert (Message_Text (S) = "Uncommented line",
              "toggle uncomment operation-specific message mismatch");
   end Test_Phase389_Uncomment_And_Toggle_Policies;


   procedure Test_Phase389_No_Op_Redo_Empty_And_Active_Buffer_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      A_Id        : Editor.Buffers.Buffer_Id;
      B_Id        : Editor.Buffers.Buffer_Id;
      Redo_Before : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "");
      Editor.State.Set_Dirty (S, False);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "",
              "comment-line empty-buffer no-op must preserve empty text");
      Assert (Message_Text (S) = "Nothing to comment",
              "comment-line empty-buffer message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "comment-line empty-buffer no-op must create no undo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "comment-line empty-buffer no-op must not dirty buffer");

      Editor.State.Load_Text (S, "Alpha");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Message_Text (S) = "Nothing to uncomment",
              "uncomment-line no-marker message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "no-op uncomment-line after undo must preserve redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "-- Alpha",
              "redo after no-op uncomment-line must still restore commented text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (B_Id /= A_Id, "new buffer must be a distinct active buffer");
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "-- Beta",
              "comment-line must mutate the active buffer");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha",
              "comment-line must not mutate inactive buffers");
      Assert (Editor.History.Undo_Stack.Is_Empty,
              "inactive buffer must not inherit line-comment undo entries");

      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "-- Beta",
              "switching back must restore active buffer line-comment text");
      Assert (not Editor.History.Undo_Stack.Is_Empty,
              "active buffer must retain its own line-comment undo entry");
   end Test_Phase389_No_Op_Redo_Empty_And_Active_Buffer_Isolation;


   procedure Test_Phase389_Indentation_And_Line_Editing_Coexistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Editor.State.Set_Dirty (S, False);

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "  -- Alpha" & ASCII.LF & "Beta",
         "indent-increase before comment-line must place marker after increased indentation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "  -- Alpha" & ASCII.LF & "  -- Alpha" & ASCII.LF & "Beta",
         "duplicate-line after comment-line must preserve exact commented line text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "  -- Alpha" & ASCII.LF & "  Alpha" & ASCII.LF & "Beta",
         "uncomment-line after duplicate-line must use current logical line prefix");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "  -- Alpha" & ASCII.LF & "Beta",
         "mixed line-comment and line-edit undo ordering must restore exact text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "  -- Alpha" & ASCII.LF & "  Alpha" & ASCII.LF & "Beta",
         "mixed line-comment and line-edit redo ordering must restore exact text");
   end Test_Phase389_Indentation_And_Line_Editing_Coexistence;


   procedure Test_Phase389_Line_Comment_Edge_Matrix_And_Redo_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Redo_Before : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, String'(1 => ' ') & String'(1 => ASCII.HT) & "Mixed" & ASCII.LF & "" & ASCII.LF & "  --" & ASCII.LF & "  -- " & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         String'(1 => ' ') & String'(1 => ASCII.HT) & "-- Mixed" & ASCII.LF & "" & ASCII.LF & "  --" & ASCII.LF & "  -- " & ASCII.LF & "Gamma",
         "comment-line must insert after mixed leading spaces/tabs");

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         String'(1 => ' ') & String'(1 => ASCII.HT) & "-- Mixed" & ASCII.LF & "-- " & ASCII.LF & "  --" & ASCII.LF & "  -- " & ASCII.LF & "Gamma",
         "comment-line must comment a blank logical line inside a non-empty buffer");

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 2, 4)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         String'(1 => ' ') & String'(1 => ASCII.HT) & "-- Mixed" & ASCII.LF & "-- " & ASCII.LF & "  " & ASCII.LF & "  -- " & ASCII.LF & "Gamma",
         "uncomment-line must remove a comment-only marker without trailing space");

      Set_Caret
        (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 3, 5)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         String'(1 => ' ') & String'(1 => ASCII.HT) & "-- Mixed" & ASCII.LF & "-- " & ASCII.LF & "  " & ASCII.LF & "  " & ASCII.LF & "Gamma",
         "uncomment-line must remove a comment-only marker with trailing space");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "text-changing comment-line after undo must clear redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (S) = "Line already commented",
              "already-commented comment-line must report no-op");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "already-commented comment-line no-op must preserve redo stack");
   end Test_Phase389_Line_Comment_Edge_Matrix_And_Redo_Preservation;


   procedure Test_Phase389_Boundaries_Availability_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      No_Buffer      : Editor.State.State_Type;
      After          : Editor.State.State_Type;
      Before_Text    : Unbounded_String;
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Snap           : Editor.Render_Model.Editor_Snapshot;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Avail          : Editor.Commands.Command_Availability;
      Binding        : Editor.Keybindings.Binding_Result;
      Resolved       : Editor.Commands.Command_Id := Editor.Commands.No_Command;

      function Ctrl_Slash return Editor.Keybindings.Key_Chord is
      begin
         return Editor.Keybindings.Key_Chord'
           (Key       => Editor.Keybindings.Key_M,
            Modifiers =>
              (Ctrl  => True,
               Shift => False,
               Alt   => False,
               Meta  => False));
      end Ctrl_Slash;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("Alpha");
      S.Active_Find_Stale := False;
      S.Active_Replace_Text := To_Unbounded_String ("ALPHA");
      S.Active_Replace_Prompt := True;
      Set_Primary_Selection (S, 0, 7);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Comment_Line);
      Assert (Editor.Commands.Is_Available (Avail),
              "comment-line availability should be side-effect-free and available with buffer/caret");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "comment-line availability must not mutate text");
      Assert (Editor.Selection.Has_Selection (S),
              "comment-line availability must not mutate selection");

      Editor.State.Init (No_Buffer);
      Avail := Editor.Executor.Command_Availability
        (No_Buffer, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No active buffer.",
              "line-comment availability without an active buffer must use canonical no-active-buffer reason");
      Editor.Executor.Execute_Command
        (No_Buffer, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "line-comment execution without an active buffer must report canonical no-active-buffer message");

      S.Carets.Clear;
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No caret location",
              "line-comment availability without a caret must use canonical no-caret reason");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Message_Text (S) = "No caret location",
              "line-comment execution without a caret must report canonical no-caret message");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "no-caret line-comment execution must not mutate text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "no-caret line-comment execution must not create an undo entry");
      Set_Primary_Selection (S, 0, 7);

      Editor.Keybindings.Bind
        (Ctrl_Slash, Editor.Commands.Command_Toggle_Line_Comment);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Ctrl_Slash);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Text_Buffer.UTF8_Text (After.Buffer) = "-- Alpha" & ASCII.LF & "Beta",
         "Input_Bridge line-comment binding must route through Executor");
      Assert (After.Active_Find_Stale,
              "line-comment mutation must invalidate Find/Replace through edit hook");
      Assert (After.Active_Replace_Text = To_Unbounded_String ("ALPHA")
              and then After.Active_Replace_Prompt,
              "line-comment mutation must not rewrite Replace policy state");
      Assert (not Editor.Selection.Has_Selection (After),
              "successful line-comment mutation must clear/collapse selection");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "line-comment commands must not mutate clipboard");
      Assert_Navigation_Counts
        (After, Before_Back, Before_Fwd,
         "line-comment commands must not record navigation history");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Input_Bridge comment route must create one undo entry");

      Binding := Editor.Keybindings.Resolve (Ctrl_Slash, Resolved);
      Assert
        (Binding = Editor.Keybindings.Bound_Command
         and then Resolved = Editor.Commands.Command_Toggle_Line_Comment,
         "runtime keybinding resolution must target canonical toggle-line-comment id");

      Snap := Editor.Render_Model.Build_Snapshot (After);
      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (After);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert (Snap.Length = Text_Buffer.Length (After.Buffer),
              "render snapshot must derive line comments from active-buffer text only");
      Assert
        (Index (Summary, "comment marker") = 0
         and then Index (Summary, "last commented") = 0
         and then Index (Summary, "last uncommented") = 0
         and then Index (Summary, "line comment") = 0
         and then Index (Summary, "-- ") = 0,
         "workspace persistence must exclude line-comment transient state/settings");
   end Test_Phase389_Boundaries_Availability_And_Persistence;



   procedure Test_Phase390_Prefix_Matrix_And_Current_Line_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      HT : constant String := String'(1 => ASCII.HT);
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "Alpha" & ASCII.LF &
         "  Alpha" & ASCII.LF &
         HT & "Alpha" & ASCII.LF &
         " " & HT & "Alpha" & ASCII.LF &
         "-- Alpha" & ASCII.LF &
         "--Alpha" & ASCII.LF &
         "Alpha -- note" & ASCII.LF &
         "  ");
      Editor.State.Set_Dirty (S, False);

      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 5)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "-- Alpha" & ASCII.LF &
              "  Alpha" & ASCII.LF &
              HT & "Alpha" & ASCII.LF &
              " " & HT & "Alpha" & ASCII.LF &
              "-- Alpha" & ASCII.LF &
              "--Alpha" & ASCII.LF &
              "Alpha -- note" & ASCII.LF &
              "  ",
              "Phase 390 comment-line must insert exactly canonical marker at unindented prefix");

      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 2, 1)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 3, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 6, 5)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 7, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "-- Alpha" & ASCII.LF &
              "  -- Alpha" & ASCII.LF &
              HT & "-- Alpha" & ASCII.LF &
              " " & HT & "-- Alpha" & ASCII.LF &
              "-- Alpha" & ASCII.LF &
              "--Alpha" & ASCII.LF &
              "-- Alpha -- note" & ASCII.LF &
              "  -- ",
              "Phase 390 comment-line prefix matrix must preserve indentation, internal markers, and whitespace lines");

      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 4, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (S) = "Line already commented",
              "Phase 390 comment-line must no-op on -- space prefix");
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 5, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (S) = "Line already commented",
              "Phase 390 comment-line must no-op on bare -- prefix");

      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 2, 1)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 3, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 6, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 7, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF &
              "  Alpha" & ASCII.LF &
              HT & "Alpha" & ASCII.LF &
              " " & HT & "Alpha" & ASCII.LF &
              "-- Alpha" & ASCII.LF &
              "--Alpha" & ASCII.LF &
              "Alpha -- note" & ASCII.LF &
              "  ",
              "Phase 390 uncomment-line matrix must remove exactly one recognized prefix marker only");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A" & ASCII.LF & "B" & ASCII.LF & "C");
      Set_Primary_Selection
        (S,
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 0)),
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "A" & ASCII.LF & "-- B" & ASCII.LF & "C",
              "Phase 390 line-comment commands must operate on the caret line only, not selected-line ranges");
   end Test_Phase390_Prefix_Matrix_And_Current_Line_Only;


   procedure Test_Phase390_Caret_Selection_Find_Clipboard_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "  Alpha" & ASCII.LF & "Beta");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("Alpha");
      S.Active_Find_Stale := False;
      S.Active_Replace_Text := To_Unbounded_String ("Omega");
      S.Active_Replace_Prompt := True;
      Set_Primary_Selection
        (S,
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 2)),
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 4)));
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "  -- Alpha" & ASCII.LF & "Beta",
              "Phase 390 comment-line must insert after indentation regardless of caret column");
      Assert_Caret_Row_Col (S, 0, 7, "Phase 390 comment-line caret shift after insertion");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 390 successful comment-line must clear stale active selection");
      Assert (S.Active_Find_Stale,
              "Phase 390 text-changing comment-line must invalidate active Find through edit hook");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Omega") and then S.Active_Replace_Prompt,
              "Phase 390 line-comment must not mutate Replace text or visibility");
      Assert (Editor.Clipboard.Has_Text and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 390 line-comment must not mutate clipboard");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "Phase 390 line-comment must not record navigation history");

      S.Active_Find_Stale := False;
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 3)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "  Alpha" & ASCII.LF & "Beta",
              "Phase 390 uncomment-line must restore exact pre-comment text");
      Assert_Caret_Row_Col (S, 0, 2,
                            "Phase 390 uncomment-line caret inside marker must clamp to marker position");
      Assert (S.Active_Find_Stale,
              "Phase 390 text-changing uncomment-line must invalidate active Find through edit hook");
      Assert (Editor.Clipboard.Has_Text and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 390 uncomment-line must preserve clipboard");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "Phase 390 uncomment-line must not record navigation history");
   end Test_Phase390_Caret_Selection_Find_Clipboard_Navigation;


   procedure Test_Phase390_Redo_Dirty_And_No_Op_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Redo_Before : Natural := 0;
      Undo_Before : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Editor.State.Is_Dirty (S),
              "Phase 390 text-changing comment-line must dirty a clean buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 390 comment-line must create one undo entry");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha",
              "Phase 390 undo after comment-line must restore exact previous text");
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Message_Text (S) = "Nothing to uncomment",
              "Phase 390 no-marker uncomment-line must report deterministic no-op");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 390 no-op uncomment-line after undo must preserve redo stack");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 390 no-op uncomment-line must not create undo entries");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "-- Alpha",
              "Phase 390 redo after no-op uncomment-line must still be available");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 390 successful comment-line after undo must clear redo stack");
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (S) = "Line already commented",
              "Phase 390 duplicate comment-line must report already-commented no-op");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 390 already-commented no-op must preserve redo stack");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 390 already-commented no-op must not create undo entry");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "",
              "Phase 390 toggle on empty buffer must preserve empty text");
      Assert (Message_Text (S) = "Nothing to comment",
              "Phase 390 toggle on empty buffer must use comment no-op message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 390 empty-buffer toggle must not create undo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 390 empty-buffer toggle must not dirty buffer");
   end Test_Phase390_Redo_Dirty_And_No_Op_Policy;


   procedure Test_Phase390_Indentation_Line_Edit_And_Toggle_Sharing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);

      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "  -- Beta" & ASCII.LF & "Gamma",
              "Phase 390 toggle comment path must place marker after current indentation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma",
              "Phase 390 outdent after comment-line must treat indentation canonically before marker");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
              "Phase 390 toggle uncomment path must share canonical marker recognition");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma",
              "Phase 390 duplicate-line after comment-line must preserve exact current-line text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma" & ASCII.LF & "-- Beta",
              "Phase 390 move-down after comment-line must preserve exact line boundaries");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma" & ASCII.LF & "Beta",
              "Phase 390 uncomment after line-edit commands must use post-edit caret line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma",
              "Phase 390 mixed line-comment and line-edit undo sequence must restore exact text");
   end Test_Phase390_Indentation_Line_Edit_And_Toggle_Sharing;


   procedure Test_Phase390_Completeness_Toggle_No_Op_Find_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Run_Toggle_Case
        (Before           : String;
         Expected_After   : String;
         Expected_Message : String;
         Expected_Undo    : Natural;
         Why              : String)
      is
         S : Editor.State.State_Type;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Before);
         Editor.State.Set_Dirty (S, False);
         Set_Caret (S, 0);
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Toggle_Line_Comment);
         Assert (Text_Buffer.UTF8_Text (S.Buffer) = Expected_After,
                 Why & ": toggle text mismatch");
         Assert (Message_Text (S) = Expected_Message,
                 Why & ": toggle message mismatch");
         Assert (Natural (Editor.History.Undo_Stack.Length) = Expected_Undo,
                 Why & ": toggle undo-entry count mismatch");
      end Run_Toggle_Case;

      S              : Editor.State.State_Type;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
   begin
      Run_Toggle_Case ("Alpha", "-- Alpha", "Commented line", 1,
                       "Phase 390 completeness toggle comments plain line");
      Run_Toggle_Case ("-- Alpha", "Alpha", "Uncommented line", 1,
                       "Phase 390 completeness toggle uncomments spaced marker");
      Run_Toggle_Case ("--Alpha", "Alpha", "Uncommented line", 1,
                       "Phase 390 completeness toggle uncomments bare marker");
      Run_Toggle_Case ("  Alpha", "  -- Alpha", "Commented line", 1,
                       "Phase 390 completeness toggle preserves leading spaces");
      Run_Toggle_Case ("  -- Alpha", "  Alpha", "Uncommented line", 1,
                       "Phase 390 completeness toggle removes marker after leading spaces");
      Run_Toggle_Case ("Alpha -- x", "-- Alpha -- x", "Commented line", 1,
                       "Phase 390 completeness toggle treats internal marker as ordinary text");
      Run_Toggle_Case ("  ", "  -- ", "Commented line", 1,
                       "Phase 390 completeness toggle comments whitespace-only line");
      Run_Toggle_Case ("", "", "Nothing to comment", 0,
                       "Phase 390 completeness toggle empty-buffer no-op");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "-- Alpha");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("Alpha");
      S.Active_Find_Stale := False;
      S.Active_Replace_Text := To_Unbounded_String ("Beta");
      S.Active_Replace_Prompt := True;
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "-- Alpha",
              "Phase 390 no-op comment-line must preserve text exactly");
      Assert (Message_Text (S) = "Line already commented",
              "Phase 390 no-op comment-line must report already-commented status");
      Assert (not S.Active_Find_Stale,
              "Phase 390 no-op comment-line must not invalidate Find/Replace");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Alpha"),
              "Phase 390 no-op comment-line must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Beta")
              and then S.Active_Replace_Prompt,
              "Phase 390 no-op comment-line must not mutate Replace state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 390 no-op comment-line must not create an undo entry");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha -- note");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("--");
      S.Active_Find_Stale := False;
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha -- note",
              "Phase 390 no-op uncomment-line must not remove an internal marker");
      Assert (Message_Text (S) = "Nothing to uncomment",
              "Phase 390 no-op uncomment-line must report deterministic no-op");
      Assert (not S.Active_Find_Stale,
              "Phase 390 no-op uncomment-line must not invalidate Find/Replace");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "comment marker") = 0
         and then Index (Summary, "last commented") = 0
         and then Index (Summary, "last uncommented") = 0
         and then Index (Summary, "line comment") = 0,
         "Phase 390 workspace snapshot must not persist line-comment transient state");
   end Test_Phase390_Completeness_Toggle_No_Op_Find_And_Persistence;


   procedure Test_Phase390_Completeness_Read_Only_Routes_And_No_Active_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Assert_No_Buffer_Command
        (Id               : Editor.Commands.Command_Id;
         Expected_Message : String;
         Why              : String)
      is
         S     : Editor.State.State_Type;
         Avail : Editor.Commands.Command_Availability;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Init (S);
         Avail := Editor.Executor.Command_Availability (S, Id);
         Assert
           (not Editor.Commands.Is_Available (Avail)
            and then Editor.Commands.Unavailable_Reason (Avail) = "No active buffer.",
            Why & ": availability must report no active buffer without side effects");
         Editor.Executor.Execute_Command (S, Id);
         Assert (Message_Text (S) = Expected_Message,
                 Why & ": execution message mismatch");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 0
                 and then Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": no-active-buffer execution must not mutate history");
      end Assert_No_Buffer_Command;

      procedure Assert_Stable_Name
        (Name : String;
         Id   : Editor.Commands.Command_Id;
         Why  : String)
      is
         Found    : Boolean := False;
         Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      begin
         Resolved := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (Found and then Resolved = Id,
                 Why & ": canonical stable command name must resolve exactly");
      end Assert_Stable_Name;

      procedure Assert_Removed_Name_Absent
        (Name : String;
         Why  : String)
      is
         Found    : Boolean := False;
         Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      begin
         Resolved := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found and then Resolved = Editor.Commands.No_Command,
                 Why & ": removed/noncanonical line-comment name must not resolve");
      end Assert_Removed_Name_Absent;

      S              : Editor.State.State_Type;
      Before_Text    : Unbounded_String;
      Before_Find    : Unbounded_String;
      Before_Replace : Unbounded_String;
      Before_Dirty   : Boolean := False;
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Before_Caret   : Cursor_Index := 0;
      Avail          : Editor.Commands.Command_Availability;
      Snap           : Editor.Render_Model.Editor_Snapshot;
   begin
      Assert_Stable_Name
        ("edit.comment.line",
         Editor.Commands.Command_Comment_Line,
         "Phase 390 completeness comment-line");
      Assert_Stable_Name
        ("edit.uncomment.line",
         Editor.Commands.Command_Uncomment_Line,
         "Phase 390 completeness uncomment-line");
      Assert_Stable_Name
        ("edit.comment.toggle-line",
         Editor.Commands.Command_Toggle_Line_Comment,
         "Phase 390 completeness toggle-line-comment");
      Assert_Removed_Name_Absent
        ("edit.comment.current-line",
         "Phase 390 completeness removed current-line comment alias");
      Assert_Removed_Name_Absent
        ("edit.line.comment",
         "Phase 390 completeness removed line-comment alias");
      Assert_Removed_Name_Absent
        ("edit.toggle-comment.line",
         "Phase 390 completeness removed toggle-comment alias");

      Assert_No_Buffer_Command
        (Editor.Commands.Command_Comment_Line,
         "No active buffer.",
         "Phase 390 completeness comment-line no active buffer");
      Assert_No_Buffer_Command
        (Editor.Commands.Command_Uncomment_Line,
         "No active buffer.",
         "Phase 390 completeness uncomment-line no active buffer");
      Assert_No_Buffer_Command
        (Editor.Commands.Command_Toggle_Line_Comment,
         "No active buffer.",
         "Phase 390 completeness toggle-line-comment no active buffer");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "  -- Alpha" & ASCII.LF & "Beta -- internal");
      Editor.State.Set_Dirty (S, True);
      Set_Primary_Selection
        (S,
         0,
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 5)));
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("Alpha");
      S.Active_Find_Stale := False;
      S.Active_Replace_Text := To_Unbounded_String ("Omega");
      S.Active_Replace_Prompt := True;

      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Find := S.Active_Find_Query;
      Before_Replace := S.Active_Replace_Text;
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Comment_Line);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 390 completeness comment-line availability should be available");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 390 completeness uncomment-line availability should be available");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 390 completeness toggle availability should be available");
      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 390 completeness render snapshot must observe text length only");

      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "Phase 390 completeness read-only paths must not mutate buffer text");
      Assert (S.Active_Find_Query = Before_Find
              and then not S.Active_Find_Stale,
              "Phase 390 completeness read-only paths must not mutate Find state");
      Assert (S.Active_Replace_Text = Before_Replace
              and then S.Active_Replace_Prompt,
              "Phase 390 completeness read-only paths must not mutate Replace state");
      Assert (Editor.Selection.Has_Selection (S),
              "Phase 390 completeness read-only paths must not normalize selection");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "Phase 390 completeness read-only paths must not mutate dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 390 completeness read-only paths must not mutate history stacks");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "Phase 390 completeness read-only paths must not move caret");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 390 completeness read-only paths must not mutate clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 390 completeness read-only paths must not mutate navigation history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "  Alpha" & ASCII.LF & "Beta -- internal",
              "Phase 390 completeness uncomment-line must remove only the active-line canonical marker");
      Assert (S.Active_Find_Query = Before_Find
              and then S.Active_Replace_Text = Before_Replace
              and then S.Active_Replace_Prompt,
              "Phase 390 completeness text-changing comment command must not rewrite Find/Replace payloads");
      Assert (S.Active_Find_Stale,
              "Phase 390 completeness text-changing comment command must invalidate Find matches");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 390 completeness text-changing command must preserve clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 390 completeness text-changing command must not mutate navigation history");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 390 completeness text-changing command must clear/collapse selection");
   end Test_Phase390_Completeness_Read_Only_Routes_And_No_Active_Buffer;



   procedure Test_Phase390_Completeness_Line_Boundaries_And_No_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Text : Unbounded_String;
      Before_Undo : Natural := 0;
      Before_Redo : Natural := 0;
      Before_Dirty : Boolean := False;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "First" & ASCII.LF &
         ASCII.LF &
         "  " & ASCII.LF &
         "Last" & ASCII.LF);
      Editor.State.Set_Dirty (S, False);

      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 2, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 3, 4)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);

      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "-- First" & ASCII.LF &
         "-- " & ASCII.LF &
         "  -- " & ASCII.LF &
         "-- Last" & ASCII.LF,
         "Phase 390 completeness must comment first, blank, whitespace-only, and trailing-newline last lines exactly");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 4,
              "Phase 390 completeness line-boundary mutations must create one undo entry per text change");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "First" & ASCII.LF & ASCII.LF & "  " & ASCII.LF & "Last" & ASCII.LF,
         "Phase 390 completeness undo chain must restore exact line terminators and blank lines");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 390 completeness undo to clean baseline must restore clean dirty state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "-- First" & ASCII.LF & ASCII.LF & "  " & ASCII.LF & "Last" & ASCII.LF,
         "Phase 390 completeness redo must replay line-comment text mutation without re-running classification on later lines");
      Assert_Caret_Row_Col (S, 0, 5,
                            "Phase 390 completeness redo after comment-line must restore canonical caret position");

      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Dirty := Editor.State.Is_Dirty (S);
      S.Carets.Clear;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (S) = "No caret location",
              "Phase 390 completeness comment-line without a caret must report no caret location");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "Phase 390 completeness no-caret comment-line must not mutate buffer text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 390 completeness no-caret comment-line must preserve undo and redo stacks");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "Phase 390 completeness no-caret comment-line must preserve dirty state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Message_Text (S) = "No caret location",
              "Phase 390 completeness uncomment-line without a caret must report no caret location");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Message_Text (S) = "No caret location",
              "Phase 390 completeness toggle-line-comment without a caret must report no caret location");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "Phase 390 completeness no-caret uncomment/toggle must not mutate buffer text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 390 completeness no-caret uncomment/toggle must preserve undo and redo stacks");
   end Test_Phase390_Completeness_Line_Boundaries_And_No_Caret;


   procedure Test_Phase390_Completeness_Active_Buffer_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Buffer_A : Editor.Buffers.Buffer_Id;
      Buffer_B : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Buffer_A := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Buffer_B := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "Gamma" & ASCII.LF & "Delta");
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Gamma" & ASCII.LF & "-- Delta",
              "Phase 390 completeness active-buffer command must mutate only current buffer text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 390 completeness active-buffer command must create active-buffer undo only");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Switch_Buffer (S, Buffer_A);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "Beta",
              "Phase 390 completeness inactive buffer A text must remain unchanged by buffer B comment command");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 390 completeness inactive buffer A undo stack must remain unchanged");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Message_Text (S) = "Nothing to uncomment",
              "Phase 390 completeness active buffer A must independently classify its current line");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 390 completeness no-op on buffer A must not synthesize redo history");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Switch_Buffer (S, Buffer_B);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Gamma" & ASCII.LF & "-- Delta",
              "Phase 390 completeness buffer B comment text must persist across active-buffer switch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 390 completeness buffer B undo stack must remain isolated and available");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Gamma" & ASCII.LF & "Delta",
              "Phase 390 completeness undo after switching back to buffer B must affect only buffer B");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Switch_Buffer (S, Buffer_A);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "Beta",
              "Phase 390 completeness buffer B undo must not mutate buffer A text");
      Assert (Editor.Buffers.Global_Active_Buffer = Buffer_A,
              "Phase 390 completeness line-comment commands must not activate another buffer");
   end Test_Phase390_Completeness_Active_Buffer_Isolation;



   procedure Test_Phase391_Line_Comment_Workflow_Matrices
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Run_Case
        (Command          : Editor.Commands.Command_Id;
         Before           : String;
         Expected_After   : String;
         Expected_Message : String;
         Expected_Undo    : Natural;
         Why              : String)
      is
         S           : Editor.State.State_Type;
         Before_Back : Natural := 0;
         Before_Fwd  : Natural := 0;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Before);
         Editor.State.Set_Dirty (S, False);
         Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
         S.Active_Find_Query := To_Unbounded_String ("Alpha");
         S.Active_Find_Stale := False;
         S.Active_Replace_Text := To_Unbounded_String ("Omega");
         S.Active_Replace_Prompt := True;
         Set_Caret (S, 0);
         Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
         Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

         Editor.Executor.Execute_Command (S, Command);

         Assert (Text_Buffer.UTF8_Text (S.Buffer) = Expected_After,
                 Why & ": exact text transform mismatch");
         Assert (Message_Text (S) = Expected_Message,
                 Why & ": primary message mismatch");
         Assert (Natural (Editor.History.Undo_Stack.Length) = Expected_Undo,
                 Why & ": undo count mismatch");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": fresh run must not synthesize redo entries");
         Assert (Editor.Clipboard.Has_Text
                 and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
                 Why & ": line comment command must not mutate clipboard");
         Assert_Navigation_Counts
           (S, Before_Back, Before_Fwd,
            Why & ": line comment command must not mutate navigation history");
         Assert (S.Active_Find_Query = To_Unbounded_String ("Alpha")
                 and then S.Active_Replace_Text = To_Unbounded_String ("Omega")
                 and then S.Active_Replace_Prompt,
                 Why & ": Find/Replace payloads must remain in their domain");

         if Expected_Undo = 0 then
            Assert (not S.Active_Find_Stale,
                    Why & ": no-op line comment command must not stale Find");
            Assert (not Editor.State.Is_Dirty (S),
                    Why & ": no-op line comment command must not dirty clean buffer");
         else
            Assert (S.Active_Find_Stale,
                    Why & ": text-changing line comment command must stale Find");
            Assert (Editor.State.Is_Dirty (S),
                    Why & ": text-changing line comment command must dirty clean buffer");
            Assert (S.Carets.Length > 0,
                    Why & ": text-changing line comment command must leave a valid caret");
            Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
            Assert (Text_Buffer.UTF8_Text (S.Buffer) = Before,
                    Why & ": undo must restore exact pre-command text");
            Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
            Assert (Text_Buffer.UTF8_Text (S.Buffer) = Expected_After,
                    Why & ": redo must restore exact post-command text");
         end if;
      end Run_Case;

      procedure Run_Redo_Preservation
        (Command          : Editor.Commands.Command_Id;
         No_Op_Text       : String;
         Expected_Message : String;
         Why              : String)
      is
         S : Editor.State.State_Type;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Init (S);
         Editor.State.Load_Text (S, No_Op_Text);
         Set_Caret (S, 0);
         if Command = Editor.Commands.Command_Comment_Line then
            Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
         else
            Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
         end if;
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
                 Why & ": setup must leave redo available");

         Set_Caret (S, 0);
         Editor.Executor.Execute_Command (S, Command);
         Assert (Message_Text (S) = Expected_Message,
                 Why & ": no-op message mismatch");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
                 Why & ": no-op line comment command must preserve redo");
      end Run_Redo_Preservation;
   begin
      Run_Case (Editor.Commands.Command_Comment_Line,
                "Alpha", "-- Alpha", "Commented line", 1,
                "Phase 391 comment plain line");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "  Alpha", "  -- Alpha", "Commented line", 1,
                "Phase 391 comment leading spaces");
      Run_Case (Editor.Commands.Command_Comment_Line,
                String'(1 => ASCII.HT) & "Alpha",
                String'(1 => ASCII.HT) & "-- Alpha",
                "Commented line", 1,
                "Phase 391 comment leading tab");
      Run_Case (Editor.Commands.Command_Comment_Line,
                " " & String'(1 => ASCII.HT) & "Alpha",
                " " & String'(1 => ASCII.HT) & "-- Alpha",
                "Commented line", 1,
                "Phase 391 comment mixed whitespace prefix");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "-- Alpha", "-- Alpha", "Line already commented", 0,
                "Phase 391 comment spaced prefix no-op");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "--Alpha", "--Alpha", "Line already commented", 0,
                "Phase 391 comment bare prefix no-op");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "Alpha -- note", "-- Alpha -- note", "Commented line", 1,
                "Phase 391 comment internal marker as text");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "  ", "  -- ", "Commented line", 1,
                "Phase 391 comment whitespace-only line");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "", "", "Nothing to comment", 0,
                "Phase 391 comment empty buffer");

      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "-- Alpha", "Alpha", "Uncommented line", 1,
                "Phase 391 uncomment spaced marker");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "--Alpha", "Alpha", "Uncommented line", 1,
                "Phase 391 uncomment bare marker");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "  -- Alpha", "  Alpha", "Uncommented line", 1,
                "Phase 391 uncomment spaces before marker");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                String'(1 => ASCII.HT) & "-- Alpha",
                String'(1 => ASCII.HT) & "Alpha",
                "Uncommented line", 1,
                "Phase 391 uncomment tab before marker");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "Alpha -- note", "Alpha -- note", "Nothing to uncomment", 0,
                "Phase 391 uncomment internal marker no-op");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "  -- ", "  ", "Uncommented line", 1,
                "Phase 391 uncomment comment-only indented line");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "--", "", "Uncommented line", 1,
                "Phase 391 uncomment bare marker-only line");

      Run_Case (Editor.Commands.Command_Toggle_Line_Comment,
                "Alpha", "-- Alpha", "Commented line", 1,
                "Phase 391 toggle comments absent marker");
      Run_Case (Editor.Commands.Command_Toggle_Line_Comment,
                "-- Alpha", "Alpha", "Uncommented line", 1,
                "Phase 391 toggle uncomments spaced marker");
      Run_Case (Editor.Commands.Command_Toggle_Line_Comment,
                "Alpha -- x", "-- Alpha -- x", "Commented line", 1,
                "Phase 391 toggle treats internal marker as ordinary text");

      Run_Redo_Preservation
        (Editor.Commands.Command_Comment_Line, "-- Alpha",
         "Line already commented",
         "Phase 391 already-commented command preserves redo");
      Run_Redo_Preservation
        (Editor.Commands.Command_Uncomment_Line, "Alpha -- note",
         "Nothing to uncomment",
         "Phase 391 no-marker uncomment preserves redo");
   end Test_Phase391_Line_Comment_Workflow_Matrices;


   procedure Test_Phase391_Line_Boundaries_Caret_Selection_And_Find
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
      Snap         : Editor.Render_Model.Editor_Snapshot;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "A" & ASCII.LF &
         "B" & ASCII.LF &
         "C" & ASCII.LF &
         ASCII.LF &
         "   " & ASCII.LF &
         String'(1 => ASCII.HT) & "D");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("B");
      S.Active_Find_Stale := False;
      S.Active_Replace_Text := To_Unbounded_String ("Bee");
      S.Active_Replace_Prompt := True;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Set_Primary_Selection
        (S,
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 0)),
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 1)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "A" & ASCII.LF &
         "-- B" & ASCII.LF &
         "C" & ASCII.LF &
         ASCII.LF &
         "   " & ASCII.LF &
         String'(1 => ASCII.HT) & "D",
         "Phase 391 comment must mutate only the caret logical line");
      Assert_Caret_Row_Col (S, 1, 4,
                            "Phase 391 comment must keep caret valid on same logical line");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 391 text-changing comment must clear/collapse active selection");
      Assert (S.Active_Find_Stale,
              "Phase 391 text-changing comment must invalidate Find ranges");
      Assert (S.Active_Find_Query = To_Unbounded_String ("B")
              and then S.Active_Replace_Text = To_Unbounded_String ("Bee")
              and then S.Active_Replace_Prompt,
              "Phase 391 line comment must not mutate Find query or Replace text");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 391 line comment must not consume clipboard while selection is present");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 391 line comment caret normalization must not record navigation");

      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 3, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 4, 3)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 5, 1)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "A" & ASCII.LF &
         "-- B" & ASCII.LF &
         "C" & ASCII.LF &
         "-- " & ASCII.LF &
         "   -- " & ASCII.LF &
         String'(1 => ASCII.HT) & "-- D",
         "Phase 391 blank, whitespace-only, and tab-leading lines must follow exact marker policy");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 4,
              "Phase 391 each text-changing line-comment command must create exactly one undo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "A" & ASCII.LF &
         "B" & ASCII.LF &
         "C" & ASCII.LF &
         ASCII.LF &
         "   " & ASCII.LF &
         String'(1 => ASCII.HT) & "D",
         "Phase 391 undo chain must restore exact line boundaries and terminators");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 391 undo to saved baseline must restore clean dirty state");

      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 391 render snapshot must observe current buffer length after undo");
   end Test_Phase391_Line_Boundaries_Caret_Selection_And_Find;


   procedure Test_Phase391_Indent_Line_Edit_Clipboard_And_Redo_Integration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));

      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "  Beta" & ASCII.LF & "Gamma",
              "Phase 391 setup indent must adjust leading whitespace before comment marker");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "  -- Beta" & ASCII.LF & "Gamma",
              "Phase 391 comment after indent must insert marker after current leading whitespace");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma",
              "Phase 391 outdent after comment must treat indentation before marker canonically");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
              "Phase 391 uncomment after outdent must remove only canonical active-line marker");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF &
              "-- Beta" & ASCII.LF & "Gamma",
              "Phase 391 duplicate-line after comment must preserve exact commented text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF &
              "Gamma" & ASCII.LF & "-- Beta",
              "Phase 391 move-down after duplicate/comment must preserve logical line boundaries");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF &
              "Gamma" & ASCII.LF & "Beta",
              "Phase 391 toggle after line move must classify post-edit current line");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 391 indentation/line-edit/comment integration must not mutate clipboard");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 391 undo after mixed workflow must expose redo");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 391 successful line-comment command after undo must clear redo");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Message_Text (S) = "No edits to redo",
              "Phase 391 redo after successful line-comment invalidation must report no redo");
   end Test_Phase391_Indent_Line_Edit_Clipboard_And_Redo_Integration;


   procedure Test_Phase391_Read_Only_Routes_Feature_Independence_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      No_Buffer      : Editor.State.State_Type;
      Before_Text    : Unbounded_String;
      Before_Find    : Unbounded_String;
      Before_Replace : Unbounded_String;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Before_Caret   : Cursor_Index := 0;
      Avail          : Editor.Commands.Command_Availability;
      Found          : Boolean := True;
      Id             : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Snap           : Editor.Render_Model.Editor_Snapshot;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Binding        : Editor.Keybindings.Binding_Result;
      Resolved       : Editor.Commands.Command_Id := Editor.Commands.No_Command;

      function Ctrl_Slash return Editor.Keybindings.Key_Chord is
      begin
         return Editor.Keybindings.Key_Chord'
           (Key       => Editor.Keybindings.Key_M,
            Modifiers =>
              (Ctrl  => True,
               Shift => False,
               Alt   => False,
               Meta  => False));
      end Ctrl_Slash;

      procedure Assert_Not_Exposed (Name : String; Why : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found and then Id = Editor.Commands.No_Command, Why);
      end Assert_Not_Exposed;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Find_Stale := False;
      S.Active_Replace_Text := To_Unbounded_String ("BETA");
      S.Active_Replace_Prompt := True;
      Set_Primary_Selection
        (S,
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 0)),
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Find := S.Active_Find_Query;
      Before_Replace := S.Active_Replace_Text;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Comment_Line);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 391 comment availability must be side-effect-free and available");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 391 uncomment availability must be side-effect-free and available");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 391 toggle availability must be side-effect-free and available");
      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 391 render snapshot must derive from canonical buffer text");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text)
              and then S.Active_Find_Query = Before_Find
              and then S.Active_Replace_Text = Before_Replace
              and then not S.Active_Find_Stale
              and then Editor.Selection.Has_Selection (S)
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "Phase 391 render/availability paths must not mutate editor state");

      Editor.State.Init (No_Buffer);
      Editor.Executor.Execute_Command (No_Buffer, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "Phase 391 comment-line without active buffer must report canonical message");
      Editor.Executor.Execute_Command (No_Buffer, Editor.Commands.Command_Uncomment_Line);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "Phase 391 uncomment-line without active buffer must report canonical message");
      Editor.Executor.Execute_Command (No_Buffer, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "Phase 391 toggle-line-comment without active buffer must report canonical message");

      Editor.Keybindings.Bind (Ctrl_Slash, Editor.Commands.Command_Toggle_Line_Comment);
      Binding := Editor.Keybindings.Resolve (Ctrl_Slash, Resolved);
      Assert (Binding = Editor.Keybindings.Bound_Command
              and then Resolved = Editor.Commands.Command_Toggle_Line_Comment,
              "Phase 391 runtime keybinding must resolve to canonical toggle-line-comment id");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "comment marker") = 0
         and then Index (Summary, "last commented") = 0
         and then Index (Summary, "last uncommented") = 0
         and then Index (Summary, "line comment") = 0
         and then Index (Summary, "language comment") = 0
         and then Index (Summary, "-- ") = 0,
         "Phase 391 workspace persistence must exclude line-comment transient state/settings");

      Assert_Not_Exposed ("edit.comment.selection",
                          "Phase 391 selected-line comment command must remain absent");
      Assert_Not_Exposed ("edit.uncomment.selection",
                          "Phase 391 selected-line uncomment command must remain absent");
      Assert_Not_Exposed ("edit.comment.block",
                          "Phase 391 block comment command must remain absent");
      Assert_Not_Exposed ("edit.comment.toggle-block",
                          "Phase 391 toggle block comment command must remain absent");
      Assert_Not_Exposed ("edit.comment.smart",
                          "Phase 391 smart comment command must remain absent");
      Assert_Not_Exposed ("edit.comment.language-aware",
                          "Phase 391 language-aware comment command must remain absent");
      Assert_Not_Exposed ("edit.comment.document",
                          "Phase 391 document comment command must remain absent");
      Assert_Not_Exposed ("edit.comment.region",
                          "Phase 391 region comment command must remain absent");
      Assert_Not_Exposed ("edit.format.document",
                          "Phase 391 format document command must remain absent");
      Assert_Not_Exposed ("edit.format.selection",
                          "Phase 391 format selection command must remain absent");
      Assert_Not_Exposed ("edit.format.on-save",
                          "Phase 391 format-on-save command must remain absent");
   end Test_Phase391_Read_Only_Routes_Feature_Independence_And_Persistence;

procedure Test_Phase392_Canonical_Line_Comment_Path_And_Persistence_Exclusion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Before_Replace : Unbounded_String;
      Before_Clip    : Unbounded_String;
      Snap           : Editor.Render_Model.Editor_Snapshot;
      Avail          : Editor.Commands.Command_Availability;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "Alpha" & ASCII.LF & "  Beta -- internal" & ASCII.LF & "--Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Find_Stale := False;
      S.Active_Replace_Text := To_Unbounded_String ("BETA");
      S.Active_Replace_Prompt := True;
      Before_Replace := S.Active_Replace_Text;
      Before_Clip := Editor.Clipboard.Get_Text;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 1)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "  -- Beta -- internal" & ASCII.LF & "--Gamma",
         "Phase 392 comment-line must use the canonical marker and leading-prefix helper");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 392 comment-line must create exactly one canonical undo entry");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 392 comment-line must dirty through canonical policy");
      Assert (S.Active_Find_Stale,
              "Phase 392 comment-line must invalidate Find through canonical edit hook");
      Assert (S.Active_Replace_Text = Before_Replace,
              "Phase 392 comment-line must not mutate Replace text");
      Assert (Editor.Clipboard.Has_Text and then Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 392 comment-line must not mutate Clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 392 comment-line must not record Navigation History");

      S.Active_Find_Stale := False;
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 2, 1)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "  -- Beta -- internal" & ASCII.LF & "Gamma",
         "Phase 392 toggle-line must use the same canonical removable-marker path as uncomment-line");
      Assert (Message_Text (S) = "Uncommented line",
              "Phase 392 toggle-line must emit one operation-specific primary message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 2,
              "Phase 392 toggle-line must create one undo entry, not two");
      Assert (S.Active_Find_Stale,
              "Phase 392 toggle-line must invalidate Find through canonical edit hook");

      S.Active_Find_Stale := False;
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 10)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "  Beta -- internal" & ASCII.LF & "Gamma",
         "Phase 392 uncomment-line must remove only one canonical prefix marker");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "  Beta -- internal" & ASCII.LF & "Gamma",
              "Phase 392 no-op uncomment-line must not remove internal markers");
      Assert (Message_Text (S) = "Nothing to uncomment",
              "Phase 392 no-op uncomment-line must report deterministic no-op");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 3,
              "Phase 392 no-op uncomment-line must not create an undo entry");
      Assert (S.Active_Find_Stale,
              "Phase 392 no-op after prior edit must not repair stale state");

      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 392 render snapshot must derive from canonical buffer text only");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 392 toggle availability must remain side-effect-free and available");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "comment marker") = 0
         and then Index (Summary, "last commented") = 0
         and then Index (Summary, "last uncommented") = 0
         and then Index (Summary, "line comment") = 0
         and then Index (Summary, "comment syntax") = 0
         and then Index (Summary, "language comment") = 0
         and then Index (Summary, "file-extension comment") = 0
         and then Index (Summary, "-- ") = 0,
         "Phase 392 workspace persistence must exclude canonical and removed line-comment state/settings");
   end Test_Phase392_Canonical_Line_Comment_Path_And_Persistence_Exclusion;


   procedure Test_Phase393_Line_Join_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Line_Join_Next) = "edit.line.join-next",
         "join-next stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Line_Join_Next).Category =
         Editor.Commands.Edit_Category,
         "join-next must be an Edit command");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Line_Join_Next),
         "join-next must be bindable");
      Assert
        (Editor.Commands.Is_Text_Editing_Command
           (Editor.Commands.Command_Line_Join_Next),
         "join-next must be classified as a text-editing command");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.line.join-next", Found);
      Assert (Found and then Id = Editor.Commands.Command_Line_Join_Next,
              "join-next stable name must resolve to canonical command id");
   end Test_Phase393_Line_Join_Command_Descriptors;


   procedure Test_Phase393_Join_Next_Separator_Matrix_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;

      procedure Check
        (Input    : String;
         Caret    : Cursor_Index;
         Expected : String;
         Why      : String)
      is
      begin
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Input);
         Editor.State.Set_Dirty (S, False);
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Set_Caret (S, Caret);
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Line_Join_Next);
         Assert (Text_Buffer.UTF8_Text (S.Buffer) = Expected,
                 Why & ": joined text mismatch");
         Assert (Message_Text (S) = "Joined line",
                 Why & ": success message mismatch");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": join must create one undo entry");
         Assert (Editor.State.Is_Dirty (S),
                 Why & ": join must dirty clean buffer");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert (Text_Buffer.UTF8_Text (S.Buffer) = Input,
                 Why & ": undo must restore exact input");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert (Text_Buffer.UTF8_Text (S.Buffer) = Expected,
                 Why & ": redo must restore exact joined text");
      end Check;
   begin
      Check ("Alpha" & ASCII.LF & "Beta", 0, "Alpha Beta",
             "two non-empty lines");
      Check ("Alpha" & ASCII.LF & "  Beta", 0, "Alpha   Beta",
             "second-line leading spaces preserved");
      Check ("Alpha " & ASCII.LF & "Beta", 0, "Alpha  Beta",
             "first-line trailing spaces preserved");
      Check (ASCII.LF & "Beta", 0, "Beta",
             "empty first line adds no separator");
      Check ("Alpha" & ASCII.LF, 0, "Alpha",
             "empty second line adds no separator");
      Check ("  " & ASCII.LF & "Beta", 0, "   Beta",
             "whitespace-only first line is not empty");
      Check ("Alpha" & ASCII.LF & "  ", 0, "Alpha   ",
             "whitespace-only second line is not empty");
      Check ("Alpha" & ASCII.LF & ASCII.HT & "Beta", 0,
             "Alpha " & ASCII.HT & "Beta",
             "tab-leading second line preserved");
   end Test_Phase393_Join_Next_Separator_Matrix_Undo_Redo;


   procedure Test_Phase393_Join_Next_Boundaries_Redo_And_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "one" & ASCII.LF & "two three",
              "join-next must join caret line with following line");
      Assert_Caret_Row_Col (S, 1, 1,
                            "join-next must keep caret on joined line and preserve column");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "successful join must create one undo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "undo after join must create redo entry");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "one" & ASCII.LF & "two" & ASCII.LF & "three",
              "last-line join must no-op");
      Assert (Message_Text (S) = "Already at last line",
              "last-line join no-op message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "last-line no-op must preserve redo stack");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "single");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "single",
              "single-line buffer join must no-op");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "single-line no-op must not create undo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "single-line no-op must not dirty buffer");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Message_Text (S) = "Nothing to join",
              "empty-buffer join no-op message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "empty-buffer no-op must not create undo entry");
   end Test_Phase393_Join_Next_Boundaries_Redo_And_Caret;


   procedure Test_Phase393_Join_Next_Boundaries_Selection_Find_Clipboard_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Clip    : Unbounded_String;
      Before_Back    : Natural := 0;
      Before_Forward : Natural := 0;
      Avail          : Editor.Commands.Command_Availability;
      Summary        : Unbounded_String;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      pragma Unreferenced (Avail);
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      S.Active_Find_Query := To_Unbounded_String ("beta");
      S.Active_Replace_Text := To_Unbounded_String ("BETA");
      Set_Primary_Selection (S, 0, 5);
      Before_Clip := Editor.Clipboard.Get_Text;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma",
              "join availability must not mutate text");
      Assert (Editor.Selection.Has_Selection (S),
              "join availability must not clear selection");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "join availability must not mutate clipboard");

      Set_Caret (S, 6);
      Set_Primary_Selection (S, 0, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "alpha" & ASCII.LF & "beta gamma",
              "join must operate on caret line only, not selected text");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful join must clear/collapse active selection");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "join must not mutate clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Forward,
         "join must not record navigation history");
      Assert (S.Active_Find_Query = To_Unbounded_String ("beta"),
              "join must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("BETA"),
              "join must not mutate Replace text");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "join separator") = 0
         and then Index (Summary, "last joined") = 0
         and then Index (Summary, "line join") = 0
         and then Index (Summary, "join-next") = 0,
         "workspace persistence must exclude line-join transient state/settings");
   end Test_Phase393_Join_Next_Boundaries_Selection_Find_Clipboard_Navigation;


   procedure Test_Phase393_Join_Next_Coexists_With_Line_Edit_Indent_And_Comment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha Beta" & ASCII.LF & "Gamma",
              "join-next must use canonical line boundary behavior before later line edits");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha Beta" & ASCII.LF & "Alpha Beta" & ASCII.LF & "Gamma",
              "duplicate-line must operate on the joined logical line");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha Beta" & ASCII.LF & "  Alpha Beta" & ASCII.LF & "Gamma",
              "indent-increase must operate on the post-join current logical line");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha Beta" & ASCII.LF & "  -- Alpha Beta" & ASCII.LF & "Gamma",
              "comment-line must treat post-join text as ordinary current-line text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha Beta" & ASCII.LF & "  Alpha Beta" & ASCII.LF & "Gamma",
              "undo after mixed join/comment/indent sequence must restore exact previous text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha Beta" & ASCII.LF & "Alpha Beta" & ASCII.LF & "Gamma",
              "mixed command undo ordering must remain coherent after join");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha Beta" & ASCII.LF & "  Alpha Beta" & ASCII.LF & "Gamma",
              "mixed command redo ordering must remain coherent after join");
   end Test_Phase393_Join_Next_Coexists_With_Line_Edit_Indent_And_Comment;


   procedure Test_Phase393_Join_Next_Does_Not_Add_Forbidden_Aliases_Or_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      S     : Editor.State.State_Type;
      Snap  : Editor.Workspace_Persistence.Workspace_Snapshot;
      Text  : Unbounded_String;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.line.join-selection", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "Phase 393 must not add selected-line join command aliases");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.join.smart", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "Phase 393 must not add smart/language-aware join aliases");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.paragraph.reflow", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "Phase 393 must not add paragraph reflow aliases");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "left" & ASCII.LF & "right");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Snap := Editor.State.Build_Workspace_Snapshot (S);
      Text := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Snap));
      Assert
        (Index (Text, "join separator") = 0
         and then Index (Text, "last joined") = 0
         and then Index (Text, "line join") = 0
         and then Index (Text, "join-next") = 0
         and then Index (Text, "reflow") = 0
         and then Index (Text, "smart join") = 0,
         "Phase 393 must persist no Line Join transient state or settings");
   end Test_Phase393_Join_Next_Does_Not_Add_Forbidden_Aliases_Or_State;


   procedure Test_Phase393_Join_Next_Input_Bridge_Route
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
      Chord : constant Editor.Keybindings.Key_Chord :=
        Editor.Keybindings.Key_Chord'
          (Key       => Editor.Keybindings.Key_M,
           Modifiers =>
             (Ctrl  => True,
              Shift => True,
              Alt   => False,
              Meta  => False));
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Keybindings.Bind
        (Chord, Editor.Commands.Command_Line_Join_Next);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      Set_Caret (S, 4);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Text_Buffer.UTF8_Text (After.Buffer) =
              "one" & ASCII.LF & "two three",
              "Input_Bridge join-next keybinding must route through Executor");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Input_Bridge join-next route must create one undo entry");

      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase393_Join_Next_Input_Bridge_Route;


   procedure Test_Phase394_Join_Next_Separator_And_Boundary_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;

      procedure Check
        (Input    : String;
         Caret    : Cursor_Index;
         Expected : String;
         Why      : String)
      is
      begin
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Input);
         Editor.State.Set_Dirty (S, False);
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Set_Caret (S, Caret);

         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Line_Join_Next);

         Assert (Text_Buffer.UTF8_Text (S.Buffer) = Expected,
                 Why & ": exact joined text mismatch");
         Assert (Message_Text (S) = "Joined line",
                 Why & ": success message mismatch");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": successful join must create exactly one undo entry");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": successful join must leave redo empty");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert (Text_Buffer.UTF8_Text (S.Buffer) = Input,
                 Why & ": undo must restore exact pre-join text");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert (Text_Buffer.UTF8_Text (S.Buffer) = Expected,
                 Why & ": redo must restore exact post-join text");
      end Check;
   begin
      Check ("Alpha" & ASCII.LF & "Beta", 0, "Alpha Beta",
             "non-empty lines use one ASCII space");
      Check ("Alpha" & ASCII.LF & "  Beta", 0, "Alpha   Beta",
             "leading spaces on second line are preserved");
      Check ("Alpha " & ASCII.LF & "Beta", 0, "Alpha  Beta",
             "trailing spaces on first line are preserved");
      Check ("Alpha " & ASCII.LF & " Beta", 0, "Alpha   Beta",
             "surrounding whitespace is not normalized");
      Check (ASCII.LF & "Beta", 0, "Beta",
             "empty current line uses no separator");
      Check ("Alpha" & ASCII.LF, 0, "Alpha",
             "empty next line uses no separator");
      Check (String'(1 => ASCII.LF), 0, "",
             "two empty logical lines collapse to canonical empty text");
      Check ("  " & ASCII.LF & "Beta", 0, "   Beta",
             "whitespace-only current line is non-empty text");
      Check ("Alpha" & ASCII.LF & "  ", 0, "Alpha   ",
             "whitespace-only next line is non-empty text");
      Check ("  " & ASCII.LF & "  ", 0, "     ",
             "both whitespace-only sides preserve all spaces plus separator");
      Check (ASCII.HT & ASCII.LF & "Beta", 0, ASCII.HT & " Beta",
             "tab-only current line is non-empty text");
      Check ("Alpha" & ASCII.LF & ASCII.HT & "Beta", 0,
             "Alpha " & ASCII.HT & "Beta",
             "tab-leading next line is preserved");
   end Test_Phase394_Join_Next_Separator_And_Boundary_Reliability;


   procedure Test_Phase394_Join_Next_No_Op_Redo_Dirty_And_Find_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "undo after join must populate redo before no-op checks");

      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "one" & ASCII.LF & "two",
              "last-line join no-op must preserve exact text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "last-line join no-op after undo must not create an undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "last-line join no-op after undo must preserve redo stack");
      Assert (not Editor.State.Is_Dirty (S),
              "last-line join no-op must preserve clean dirty state");

      Set_Caret (S, 0);
      S.Active_Find_Query := To_Unbounded_String ("one two");
      S.Active_Find_Stale := False;
      S.Active_Replace_Text := To_Unbounded_String ("ONE TWO");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "one two",
              "successful join after undo must produce expected text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "successful join after undo must clear redo stack");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "successful join must invalidate active find matches through text-edit hook");
      Assert (S.Active_Find_Query = To_Unbounded_String ("one two"),
              "join must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("ONE TWO"),
              "join must not mutate Replace text");
   end Test_Phase394_Join_Next_No_Op_Redo_Dirty_And_Find_Policy;


   procedure Test_Phase394_Join_Next_Caret_Selection_Clipboard_Navigation_And_Render
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Snap           : Editor.Render_Model.Editor_Snapshot;
      Before_Clip    : Unbounded_String;
      Before_Back    : Natural := 0;
      Before_Forward : Natural := 0;
      Avail          : Editor.Commands.Command_Availability;
      Before_Text    : Unbounded_String;
      pragma Unreferenced (Avail);
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Set_Primary_Selection (S, 0, 12);
      S.Active_Find_Query := To_Unbounded_String ("Beta Gamma");
      S.Active_Find_Stale := False;
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Clip := Editor.Clipboard.Get_Text;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Join_Next);
      Assert (To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer)) = Before_Text,
              "join availability must not mutate active-buffer text");
      Assert (Editor.Selection.Has_Selection (S),
              "join availability must not normalize or clear selection");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "join availability must not read/replace clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Forward,
         "join availability must not mutate navigation history");

      Set_Caret (S, 8);
      Set_Primary_Selection (S, 0, 16);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "Beta Gamma",
              "join must operate only on caret line, not selected-line span");
      Assert_Caret_Row_Col (S, 1, 2,
                            "join must keep caret on joined logical line with valid column");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful join must clear/collapse active selection");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "join must not mutate clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Forward,
         "join caret normalization must not record navigation history");

      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "Beta Gamma",
              "render snapshot must not perform additional line joining");
      Assert (Snap.Primary_Caret_Row = 1,
              "render snapshot caret row must derive from canonical post-join caret");
      Assert (not Editor.Selection.Has_Selection (S),
              "render snapshot must not recreate a selection");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "render snapshot must not mutate clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Forward,
         "render snapshot must not mutate navigation history");
   end Test_Phase394_Join_Next_Caret_Selection_Clipboard_Navigation_And_Render;


   procedure Test_Phase394_Join_Next_Mixed_Current_Line_Command_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "  Beta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "  Alpha   Beta" & ASCII.LF & "Gamma",
              "indent then join must preserve second-line indentation as ordinary text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "  Alpha   Beta" & ASCII.LF &
              "  Alpha   Beta" & ASCII.LF & "Gamma",
              "duplicate-line after join must use the joined logical line");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "  Alpha   Beta" & ASCII.LF &
              "  -- Alpha   Beta" & ASCII.LF & "Gamma",
              "comment-line after join must treat joined text as ordinary current line");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "  Alpha   Beta" & ASCII.LF &
              "  Alpha   Beta" & ASCII.LF & "Gamma",
              "undo must restore exact pre-comment mixed workflow text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "  Alpha   Beta" & ASCII.LF & "Gamma",
              "undo must restore exact pre-duplicate mixed workflow text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "  Alpha" & ASCII.LF & "  Beta" & ASCII.LF & "Gamma",
              "undo must restore exact pre-join mixed workflow text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "  Alpha   Beta" & ASCII.LF & "Gamma",
              "redo must restore exact post-join mixed workflow text");
   end Test_Phase394_Join_Next_Mixed_Current_Line_Command_Workflows;


   procedure Test_Phase395_Join_Next_End_To_End_And_Separator_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Clip : constant Unbounded_String := To_Unbounded_String ("CLIP");

      procedure Check_Changing
        (Input          : String;
         Caret          : Cursor_Index;
         Expected       : String;
         Expected_Lines : Natural;
         Expected_Row   : Natural;
         Expected_Col   : Natural;
         Why            : String)
      is
      begin
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Input);
         Editor.State.Set_Dirty (S, False);
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.Clipboard.Set_Text (Before_Clip);
         Set_Caret (S, Caret);

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
         Assert_Line_Join_Coherent
           (S, Expected, Expected_Lines, Expected_Row, Expected_Col,
            1, 0, "Joined line", True, False, Before_Clip, 0, 0, Why);

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert_Buffer_Text (S, Input, Why & ": undo must restore exact input");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
                 Why & ": undo must create one redo entry");
         Assert (Editor.Clipboard.Get_Text = Before_Clip,
                 Why & ": undo must not change Clipboard");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert_Buffer_Text (S, Expected, Why & ": redo must restore exact join output");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": redo must restore one undo entry");
      end Check_Changing;

      procedure Check_No_Op
        (Input        : String;
         Caret        : Cursor_Index;
         Expected_Msg : String;
         Why          : String)
      is
      begin
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Input);
         Editor.State.Set_Dirty (S, False);
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Set_Caret (S, Caret);
         Editor.Clipboard.Set_Text (Before_Clip);
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);

         Assert_Buffer_Text (S, Input, Why & ": no-op must preserve text");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
                 Why & ": no-op must not create undo entry");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": no-op must not create redo entry");
         Assert (not Editor.State.Is_Dirty (S),
                 Why & ": no-op must preserve clean dirty state");
         Assert (Editor.Clipboard.Get_Text = Before_Clip,
                 Why & ": no-op must not change Clipboard");
         Assert (Message_Text (S) = Expected_Msg,
                 Why & ": no-op message mismatch");
      end Check_No_Op;
   begin
      Check_Changing ("Alpha" & ASCII.LF & "Beta", 0, "Alpha Beta",
                      1, 0, 0, "plain boundary");
      Check_Changing ("Alpha" & ASCII.LF & "  Beta", 0, "Alpha   Beta",
                      1, 0, 0, "leading whitespace is preserved");
      Check_Changing ("Alpha " & ASCII.LF & "Beta", 0, "Alpha  Beta",
                      1, 0, 0, "trailing whitespace is preserved");
      Check_Changing ("Alpha " & ASCII.LF & " Beta", 0, "Alpha   Beta",
                      1, 0, 0, "both-side whitespace is preserved");
      Check_Changing (ASCII.LF & "Beta", 0, "Beta",
                      1, 0, 0, "empty current line adds no separator");
      Check_Changing ("Alpha" & ASCII.LF, 0, "Alpha",
                      1, 0, 0, "empty following line adds no separator");
      Check_Changing (String'(1 => ASCII.LF), 0, "",
                      1, 0, 0, "two empty logical lines become canonical empty buffer text");
      Check_Changing ("  " & ASCII.LF & "Beta", 0, "   Beta",
                      1, 0, 0, "whitespace-only current line is not empty");
      Check_Changing ("Alpha" & ASCII.LF & "  ", 0, "Alpha   ",
                      1, 0, 0, "whitespace-only following line is not empty");
      Check_Changing ("  " & ASCII.LF & "  ", 0, "     ",
                      1, 0, 0, "two whitespace-only lines keep all whitespace and one separator");
      Check_Changing (ASCII.HT & ASCII.LF & "Beta", 0, ASCII.HT & " Beta",
                      1, 0, 0, "tab-only current line is not empty");
      Check_Changing ("Alpha" & ASCII.LF & ASCII.HT & "Beta", 0,
                      "Alpha " & ASCII.HT & "Beta",
                      1, 0, 0, "tab-leading following line is preserved");
      Check_Changing ("A" & ASCII.LF & "B" & ASCII.LF & "C", 2,
                      "A" & ASCII.LF & "B C",
                      2, 1, 0, "middle line joins only its following logical line");
      Check_Changing ("A" & ASCII.LF & "" & ASCII.LF & "C", 0,
                      "A" & ASCII.LF & "C",
                      2, 0, 0, "blank middle line boundary remains exact after first join");

      Check_No_Op ("", 0, "Nothing to join", "empty buffer");
      Check_No_Op ("single", 0, "Already at last line", "single-line buffer");
      Check_No_Op ("A" & ASCII.LF & "B", 2, "Already at last line",
                   "last logical line");
   end Test_Phase395_Join_Next_End_To_End_And_Separator_Workflows;


   procedure Test_Phase395_Join_Next_Caret_Selection_Find_Clipboard_And_Render_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Snap           : Editor.Render_Model.Editor_Snapshot;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Back    : Natural := 0;
      Before_Forward : Natural := 0;
      Before_Text    : Unbounded_String;
      Before_Query   : constant Unbounded_String := To_Unbounded_String ("Beta Gamma");
      Before_Replace : constant Unbounded_String := To_Unbounded_String ("BETA GAMMA");
      Avail          : Editor.Commands.Command_Availability;
      pragma Unreferenced (Avail);
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      S.Active_Find_Query := Before_Query;
      S.Active_Find_Stale := False;
      S.Active_Replace_Text := Before_Replace;
      S.Active_Replace_Prompt := True;
      Set_Primary_Selection (S, 0, 16);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Before_Text := To_Unbounded_String (Buffer_Text (S));

      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (To_Unbounded_String (Buffer_Text (S)) = Before_Text,
              "Phase 395 render snapshot must not join or repair text");
      Assert (Snap.Selection_Count = 1,
              "Phase 395 render snapshot must expose the pre-join selection without consuming it");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Join_Next);
      Assert (To_Unbounded_String (Buffer_Text (S)) = Before_Text,
              "Phase 395 availability must not mutate text");
      Assert (Editor.Selection.Has_Selection (S),
              "Phase 395 availability must not collapse selection");
      Assert (S.Active_Find_Query = Before_Query
              and then S.Active_Replace_Text = Before_Replace
              and then S.Active_Replace_Prompt,
              "Phase 395 availability must not mutate Find/Replace state");

      Set_Primary_Selection
        (S, 0, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);

      Assert_Line_Join_Coherent
        (S, "Alpha" & ASCII.LF & "Beta Gamma", 2, 1, 2,
         1, 0, "Joined line", True, False, Before_Clip,
         Before_Back, Before_Forward,
         "Phase 395 selected text is not consumed; caret line joins only next line");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Phase 395 text-changing join must invalidate Find ranges");
      Assert (S.Active_Find_Query = Before_Query,
              "Phase 395 Line Join must not mutate Find query");
      Assert (S.Active_Replace_Text = Before_Replace and then S.Active_Replace_Prompt,
              "Phase 395 Line Join must not mutate Replace prompt/text");

      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Snap.Primary_Caret_Row = 1 and then Snap.Primary_Caret_Col = 2,
              "Phase 395 render snapshot must derive caret from canonical post-join state");
      Assert (Snap.Selection_Count = 0,
              "Phase 395 render snapshot must not render stale pre-join selection");
      Assert (Snap.Active_Find_Match_Count = 0,
              "Phase 395 render snapshot must not render stale pre-join Find ranges");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
                          "Phase 395 undo restores exact pre-join text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta Gamma",
                          "Phase 395 redo restores exact post-join text");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 395 Undo/Redo around Line Join must not mutate Clipboard");
      Assert_Navigation_Counts (S, Before_Back, Before_Forward,
                                "Phase 395 Undo/Redo around Line Join must not record Navigation History");
   end Test_Phase395_Join_Next_Caret_Selection_Find_Clipboard_And_Render_Workflow;


   procedure Test_Phase395_Join_Next_Redo_Dirty_And_Mixed_Command_Coexistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Clip : constant Unbounded_String := To_Unbounded_String ("CLIP");
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "one two", "Phase 395 initial join for redo invalidation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "one" & ASCII.LF & "two",
                          "Phase 395 undo before redo invalidation restores baseline");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 395 ordinary successful edit after undo clears redo stack");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 395 no-op last-line join must preserve redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "  one" & ASCII.LF & "two",
                          "Phase 395 redo after no-op join restores preserved redo edit");

      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "Alpha" & ASCII.LF & "  Beta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Alpha" & ASCII.LF &
                          "  Beta" & ASCII.LF & "Gamma",
                          "Phase 395 duplicate-line precondition");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Alpha   Beta" & ASCII.LF & "Gamma",
                          "Phase 395 duplicate-line then join uses canonical logical boundary");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "-- Alpha   Beta" & ASCII.LF & "Gamma",
                          "Phase 395 comment-line after join treats joined line as plain text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Alpha   Beta" & ASCII.LF & "Gamma",
                          "Phase 395 uncomment-line after join removes only canonical prefix marker");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "  Alpha   Beta" & ASCII.LF & "Gamma",
                          "Phase 395 indent after join operates on joined logical line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Alpha   Beta" & ASCII.LF & "Gamma",
                          "Phase 395 outdent after join operates on joined logical line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Gamma" & ASCII.LF & "Alpha   Beta",
                          "Phase 395 move-down after join keeps line boundaries deterministic");
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Alpha   Beta",
                          "Phase 395 delete-line after join deletes the selected current logical line only");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 395 mixed current-line commands must not attribute Clipboard changes to Line Join");
   end Test_Phase395_Join_Next_Redo_Dirty_And_Mixed_Command_Coexistence;


   procedure Test_Phase395_Join_Next_Active_Buffer_Routes_Features_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      A_Id           : Editor.Buffers.Buffer_Id;
      B_Id           : Editor.Buffers.Buffer_Id;
      Candidates     : Editor.Commands.Command_Descriptor_Vectors.Vector;
      Join_Count     : Natural := 0;
      Found          : Boolean := False;
      Id             : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;

      procedure Assert_Not_Exposed (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert ((not Found) and then Id = Editor.Commands.No_Command,
                 "Phase 395 non-goal command must not be exposed: " & Name);
      end Assert_Not_Exposed;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "Delta" & ASCII.LF & "Epsilon" & ASCII.LF & "Zeta");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Set_Caret (S, 0);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "Alpha Beta" & ASCII.LF & "Gamma",
                          "Phase 395 join in buffer A changes only buffer A");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 395 buffer A join creates one active-buffer undo entry");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text (S, "Delta" & ASCII.LF & "Epsilon" & ASCII.LF & "Zeta",
                          "Phase 395 buffer B text remains unchanged after buffer A join");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 395 buffer B undo stack remains unchanged after buffer A join");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "Delta Epsilon" & ASCII.LF & "Zeta",
                          "Phase 395 buffer B joins independently");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Delta" & ASCII.LF & "Epsilon" & ASCII.LF & "Zeta",
                          "Phase 395 undo in buffer B affects only buffer B");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text (S, "Alpha Beta" & ASCII.LF & "Gamma",
                          "Phase 395 switching back preserves buffer A joined text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
                          "Phase 395 undo in buffer A affects only buffer A");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Quick" & ASCII.LF & "Open" & ASCII.LF & "Search");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      S.Active_Find_Query := To_Unbounded_String ("Quick Open");
      S.Active_Replace_Text := To_Unbounded_String ("QO");
      S.Active_Find_Stale := False;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Filtered_Commands (Candidates);
      for C of Candidates loop
         if C.Id = Editor.Commands.Command_Line_Join_Next then
            Join_Count := Join_Count + 1;
         end if;
      end loop;
      Assert (Join_Count = 1,
              "Phase 395 command palette must project exactly one canonical join-next command");
      Assert_Buffer_Text (S, "Quick" & ASCII.LF & "Open" & ASCII.LF & "Search",
                          "Phase 395 command palette projection must not join text");

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "Quick Open" & ASCII.LF & "Search",
                          "Phase 395 route coverage command id must execute canonical join");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 395 route coverage join must not mutate Clipboard");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "Phase 395 route coverage join must not mutate Navigation History");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "last joined") = 0
         and then Index (Summary, "join separator") = 0
         and then Index (Summary, "join policy") = 0
         and then Index (Summary, "line join") = 0
         and then Index (Summary, "join-next") = 0
         and then Index (Summary, "language-aware join") = 0
         and then Index (Summary, "Quick Open") = 0,
         "Phase 395 workspace persistence must exclude Line Join transient/settings state");

      Assert_Not_Exposed ("edit.line.join-selection");
      Assert_Not_Exposed ("edit.line.join-all");
      Assert_Not_Exposed ("edit.line.join-paragraph");
      Assert_Not_Exposed ("edit.line.split");
      Assert_Not_Exposed ("edit.paragraph.reflow");
      Assert_Not_Exposed ("edit.format.document");
      Assert_Not_Exposed ("edit.format.selection");
      Assert_Not_Exposed ("edit.join.smart");
      Assert_Not_Exposed ("edit.join.language-aware");
   end Test_Phase395_Join_Next_Active_Buffer_Routes_Features_And_Persistence;
procedure Test_Phase396_Line_Join_Canonical_Behavior_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("clipboard seed");
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      R              : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Initialize (S);
      Editor.State.Load_Text (S, "Alpha " & ASCII.LF & ASCII.HT & "Beta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 6);
      Set_Primary_Selection (S, 8, 6);
      Editor.Clipboard.Set_Text (Before_Clip);
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Replace_Text := To_Unbounded_String ("BETA");
      S.Active_Find_Stale := False;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Line_Join_Coherent
        (S,
         "Alpha  " & ASCII.HT & "Beta" & ASCII.LF & "Gamma",
         2, 0, 6, 1, 0, "Joined line", True, False,
         Before_Clip, Before_Back, Before_Fwd,
         "Phase 396 canonical Line Join behavior preservation");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Phase 396 Line Join must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("BETA"),
              "Phase 396 Line Join must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "Phase 396 Line Join must use canonical Find/Replace invalidation hook");

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text (S, "Alpha  " & ASCII.HT & "Beta" & ASCII.LF & "Gamma",
                          "Phase 396 render snapshot must not perform Line Join repairs");
      Assert (R.Primary_Caret_Row = 0,
              "Phase 396 render caret row must derive from canonical caret state");
      Assert (R.Selection_Count = 0,
              "Phase 396 render snapshot must not expose stale Line Join selection state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha " & ASCII.LF & ASCII.HT & "Beta" & ASCII.LF & "Gamma",
                          "Phase 396 undo must restore captured pre-join text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha  " & ASCII.HT & "Beta" & ASCII.LF & "Gamma",
                          "Phase 396 redo must restore captured post-join text without re-running join logic");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "last joined") = 0
         and then Index (Summary, "join separator") = 0
         and then Index (Summary, "join policy") = 0
         and then Index (Summary, "line join") = 0
         and then Index (Summary, "join-next") = 0
         and then Index (Summary, "language-aware join") = 0
         and then Index (Summary, "paragraph reflow") = 0
         and then Index (Summary, "format selection") = 0,
         "Phase 396 workspace persistence must exclude canonical and removed Line Join state/settings");
   end Test_Phase396_Line_Join_Canonical_Behavior_And_Persistence;



   procedure Test_Phase397_Line_Split_Command_Descriptors_And_Routes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Found : Boolean := False;
      Desc  : Editor.Commands.Command_Descriptor;
      Cmd   : Editor.Commands.Command;
      S     : Editor.State.State_Type;
      Availability : Editor.Commands.Command_Availability;
      Before_Text  : Unbounded_String;
      Before_Caret : Cursor_Index := 0;
      Before_Undo  : Natural := 0;
      Before_Redo  : Natural := 0;

      procedure Assert_Not_Exposed (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found and then Id = Editor.Commands.No_Command,
                 Name & " must not be exposed as a split command");
      end Assert_Not_Exposed;
   begin
      Desc := Editor.Commands.Descriptor
        (Editor.Commands.Command_Line_Split_At_Caret);
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Line_Split_At_Caret) =
         "edit.line.split-at-caret",
         "Phase 397 split stable command name mismatch");
      Assert (Desc.Category = Editor.Commands.Edit_Category,
              "Phase 397 split must be an Edit command");
      Assert (Desc.Visibility = Editor.Commands.Palette_Command,
              "Phase 397 split must be visible in the Command Palette");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Line_Split_At_Caret),
         "Phase 397 split must be bindable");
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Cmd.Kind = Editor.Commands.Split_Current_Line_At_Caret,
              "Phase 397 split command must map to canonical edit kind");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.line.split-at-caret", Found);
      Assert (Found and then Id = Editor.Commands.Command_Line_Split_At_Caret,
              "Phase 397 split stable name must resolve back to command id");
      Assert_Not_Exposed ("edit.line.split");
      Assert_Not_Exposed ("edit.line.split-selection");
      Assert_Not_Exposed ("edit.line.split-all");
      Assert_Not_Exposed ("edit.line.split-paragraph");
      Assert_Not_Exposed ("edit.split.smart");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 5);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "Phase 397 split availability must not mutate text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "Phase 397 split availability must not move caret");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "Phase 397 split availability must not mutate undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 397 split availability must not mutate redo stack");
   end Test_Phase397_Line_Split_Command_Descriptors_And_Routes;


   procedure Test_Phase397_Line_Split_Boundary_Matrix_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;

      procedure Check
        (Input        : String;
         Caret        : Cursor_Index;
         Expected     : String;
         Expected_Row : Natural;
         Why          : String)
      is
      begin
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Input);
         Editor.State.Set_Dirty (S, False);
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Set_Caret (S, Caret);

         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Line_Split_At_Caret);

         Assert_Buffer_Text (S, Expected, Why);
         Assert_Caret_Row_Col (S, Expected_Row, 0, Why);
         Assert (Message_Text (S) = "Split line",
                 Why & ": success message mismatch");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": split must create exactly one undo entry");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": split must leave redo stack empty");
         Assert (Editor.State.Is_Dirty (S),
                 Why & ": text-changing split must dirty the buffer");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert_Buffer_Text (S, Input, Why & " undo");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert_Buffer_Text (S, Expected, Why & " redo");
      end Check;
   begin
      Check ("AlphaBeta", 5,
             "Alpha" & ASCII.LF & "Beta", 1,
             "Phase 397 split in middle of one-line buffer");
      Check ("Alpha", 0,
             ASCII.LF & "Alpha", 1,
             "Phase 397 split at beginning of line");
      Check ("Alpha", 5,
             "Alpha" & ASCII.LF, 1,
             "Phase 397 split at end of line");
      Check ("", 0,
             String'(1 => ASCII.LF), 1,
             "Phase 397 split empty buffer as boundary insertion");
      Check ("  AlphaBeta", 2,
             "  " & ASCII.LF & "AlphaBeta", 1,
             "Phase 397 split preserves leading whitespace before caret");
      Check ("Alpha  Beta", 5,
             "Alpha" & ASCII.LF & "  Beta", 1,
             "Phase 397 split preserves whitespace after caret");
      Check ("one" & ASCII.LF & "twoThree" & ASCII.LF & "four", 7,
             "one" & ASCII.LF & "two" & ASCII.LF & "Three" & ASCII.LF & "four", 2,
             "Phase 397 split middle line only");
   end Test_Phase397_Line_Split_Boundary_Matrix_Undo_Redo;


   procedure Test_Phase397_Line_Split_State_Boundaries_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      After          : Editor.State.State_Type;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("clipboard seed");
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      R              : Editor.Render_Model.Render_Snapshot;
      Chord          : constant Editor.Keybindings.Key_Chord :=
        Editor.Keybindings.Key_Chord'
          (Key       => Editor.Keybindings.Key_N,
           Modifiers =>
             (Ctrl  => True,
              Shift => True,
              Alt   => False,
              Meta  => False));
   begin
      Editor.State.Initialize (S);
      Editor.State.Load_Text (S, "AlphaBeta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Primary_Selection (S, 0, 5);
      Editor.Clipboard.Set_Text (Before_Clip);
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Replace_Text := To_Unbounded_String ("BETA");
      S.Active_Find_Stale := False;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);

      Assert_Line_Join_Coherent
        (S,
         "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         3, 1, 0, 1, 0, "Split line", True, False,
         Before_Clip, Before_Back, Before_Fwd,
         "Phase 397 split state boundaries");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Phase 397 split must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("BETA"),
              "Phase 397 split must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "Phase 397 split must use canonical Find/Replace invalidation hook");

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "Phase 397 render snapshot must not perform line splitting");
      Assert (R.Primary_Caret_Row = 1,
              "Phase 397 render caret row must derive from split caret state");
      Assert (R.Selection_Count = 0,
              "Phase 397 render snapshot must not expose stale split selection state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta Gamma",
         "Phase 397 split must coexist with canonical Line Join policy");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "Phase 397 undo after mixed split/join must restore split text");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "last split") = 0
         and then Index (Summary, "split line") = 0
         and then Index (Summary, "split column") = 0
         and then Index (Summary, "split policy") = 0
         and then Index (Summary, "auto-indent") = 0
         and then Index (Summary, "language-aware split") = 0,
         "Phase 397 workspace persistence must exclude Line Split transient state/settings");

      Editor.Keybindings.Bind
        (Chord, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "oneTwo");
      Set_Caret (S, 3);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Text_Buffer.UTF8_Text (After.Buffer) =
              "one" & ASCII.LF & "Two",
              "Phase 397 Input_Bridge split keybinding must route through Executor");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 397 Input_Bridge split route must create one undo entry");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase397_Line_Split_State_Boundaries_And_Persistence;


   procedure Test_Phase397_Completeness_No_Op_Redo_And_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Assert_No_Buffer_Command is
         S     : Editor.State.State_Type;
         Avail : Editor.Commands.Command_Availability;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Init (S);
         Avail := Editor.Executor.Command_Availability
           (S, Editor.Commands.Command_Line_Split_At_Caret);
         Assert
           (not Editor.Commands.Is_Available (Avail)
            and then Editor.Commands.Unavailable_Reason (Avail) = "No active buffer.",
            "Phase 397 split availability without active buffer must report no active buffer");
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Line_Split_At_Caret);
         Assert (Message_Text (S) = "No active buffer.",
                 "Phase 397 split execution without active buffer must report no active buffer");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 0
                 and then Natural (Editor.History.Redo_Stack.Length) = 0,
                 "Phase 397 no-active-buffer split must not mutate history");
      end Assert_No_Buffer_Command;

      procedure Assert_No_Caret_Command is
         S           : Editor.State.State_Type;
         Avail       : Editor.Commands.Command_Availability;
         Before_Text : Unbounded_String;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Init (S);
         Editor.State.Load_Text (S, "AlphaBeta");
         Editor.State.Set_Dirty (S, False);
         S.Carets.Clear;
         Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
         Avail := Editor.Executor.Command_Availability
           (S, Editor.Commands.Command_Line_Split_At_Caret);
         Assert
           (not Editor.Commands.Is_Available (Avail)
            and then Editor.Commands.Unavailable_Reason (Avail) = "No caret location",
            "Phase 397 split availability without caret must report no caret location");
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Line_Split_At_Caret);
         Assert (Message_Text (S) = "No caret location",
                 "Phase 397 split execution without caret must report no caret location");
         Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
                 "Phase 397 no-caret split must not mutate text");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 0
                 and then Natural (Editor.History.Redo_Stack.Length) = 0,
                 "Phase 397 no-caret split must not mutate history");
      end Assert_No_Caret_Command;

      S              : Editor.State.State_Type;
      Before_Text    : Unbounded_String;
      Before_Dirty   : Boolean := False;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("clip");
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
   begin
      Assert_No_Buffer_Command;
      Assert_No_Caret_Command;

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, ASCII.LF & ASCII.HT & "Tabbed" & ASCII.LF & "Tail");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (Before_Clip);
      Set_Caret (S, 1);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Line_Join_Coherent
        (S,
         ASCII.LF & ASCII.LF & ASCII.HT & "Tabbed" & ASCII.LF & "Tail",
         4, 2, 0, 1, 0, "Split line", True, False,
         Before_Clip, Before_Back, Before_Fwd,
         "Phase 397 split blank line before tab-leading line");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, ASCII.LF & ASCII.HT & "Tabbed" & ASCII.LF & "Tail",
         "Phase 397 undo restores blank/tab-leading split source exactly");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, ASCII.LF & ASCII.LF & ASCII.HT & "Tabbed" & ASCII.LF & "Tail",
         "Phase 397 redo restores blank/tab-leading split result exactly");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 397 undo before failed split must leave one redo entry");
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer) + 20));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Message_Text (S) = "Could not split line",
              "Phase 397 invalid-caret split must report deterministic failure");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "Phase 397 failed split after undo must not mutate text");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "Phase 397 failed split after undo must preserve dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "Phase 397 failed split after undo must preserve undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 397 failed split after undo must preserve redo stack");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 397 failed split must not mutate clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 397 failed split must not mutate navigation history");

      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, To_String (Before_Text) & ASCII.LF,
         "Phase 397 successful split after undo must clear redo and append one boundary at EOF");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 397 successful split after undo must clear redo stack");
   end Test_Phase397_Completeness_No_Op_Redo_And_Boundaries;

   procedure Test_Phase398_Line_Split_Exact_Position_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;

      procedure Check
        (Input        : String;
         Caret        : Cursor_Index;
         Expected     : String;
         Expected_Row : Natural;
         Why          : String)
      is
         Before_Undo : Natural := 0;
         Before_Redo : Natural := 0;
      begin
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Input);
         Editor.State.Set_Dirty (S, False);
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Set_Caret (S, Caret);
         Before_Undo := Natural (Editor.History.Undo_Stack.Length);
         Before_Redo := Natural (Editor.History.Redo_Stack.Length);

         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Line_Split_At_Caret);

         Assert_Buffer_Text (S, Expected, Why);
         Assert_Caret_Row_Col (S, Expected_Row, 0, Why);
         Assert (Message_Text (S) = "Split line",
                 Why & ": command message mismatch");
         Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo + 1,
                 Why & ": successful split must create exactly one undo entry");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": successful split must clear redo stack only by text mutation");
         Assert (Editor.State.Is_Dirty (S),
                 Why & ": successful split must dirty a clean buffer");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert_Buffer_Text (S, Input, Why & " undo restores exact source text");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert_Buffer_Text (S, Expected, Why & " redo restores exact split text");
      end Check;
   begin
      Check ("Alpha", 0,
             ASCII.LF & "Alpha", 1,
             "Phase 398 split at line start");
      Check ("AlphaBeta", 5,
             "Alpha" & ASCII.LF & "Beta", 1,
             "Phase 398 split in middle of line");
      Check ("Alpha", 5,
             "Alpha" & ASCII.LF, 1,
             "Phase 398 split at line end");
      Check ("  Alpha", 2,
             "  " & ASCII.LF & "Alpha", 1,
             "Phase 398 split inside leading whitespace");
      Check ("  AlphaBeta", 7,
             "  Alpha" & ASCII.LF & "Beta", 1,
             "Phase 398 split after leading whitespace text");
      Check ("Alpha  Beta", 5,
             "Alpha" & ASCII.LF & "  Beta", 1,
             "Phase 398 split before trailing whitespace segment");
      Check ("Alpha  Beta", 7,
             "Alpha  " & ASCII.LF & "Beta", 1,
             "Phase 398 split after trailing whitespace segment");
      Check (ASCII.HT & "Alpha", 1,
             ASCII.HT & ASCII.LF & "Alpha", 1,
             "Phase 398 split after tab prefix");
      Check (ASCII.HT & "AlphaBeta", 6,
             ASCII.HT & "Alpha" & ASCII.LF & "Beta", 1,
             "Phase 398 split tab-leading text");
      Check ("   ", 3,
             "   " & ASCII.LF, 1,
             "Phase 398 split whitespace-only line end");
      Check ("", 0,
             String'(1 => ASCII.LF), 1,
             "Phase 398 empty buffer split uses canonical two-empty-lines representation");
      Check ("A" & ASCII.LF & "BC" & ASCII.LF & "D", 4,
             "A" & ASCII.LF & "B" & ASCII.LF & "C" & ASCII.LF & "D", 2,
             "Phase 398 split middle logical line in multiline buffer");
      Check ("A" & ASCII.LF & "B" & ASCII.LF & "C", 2,
             "A" & ASCII.LF & ASCII.LF & "B" & ASCII.LF & "C", 2,
             "Phase 398 split at start of middle logical line");
      Check ("A" & ASCII.LF & "B" & ASCII.LF & "C", 3,
             "A" & ASCII.LF & "B" & ASCII.LF & ASCII.LF & "C", 2,
             "Phase 398 split at end of middle logical line before terminator");
      Check ("A" & ASCII.LF & "B", 3,
             "A" & ASCII.LF & "B" & ASCII.LF, 2,
             "Phase 398 split at EOF appends exactly one canonical boundary");
   end Test_Phase398_Line_Split_Exact_Position_Matrix;


   procedure Test_Phase398_Line_Split_Selection_Find_Clipboard_Navigation_And_Render
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      R             : Editor.Render_Model.Render_Snapshot;
      Before_Clip   : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Back   : Natural := 0;
      Before_Fwd    : Natural := 0;
      Before_Undo   : Natural := 0;
      Before_Redo   : Natural := 0;
      Before_Dirty  : Boolean := False;
      Before_Text   : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Primary_Selection (S, 0, 5);
      Editor.Clipboard.Set_Text (Before_Clip);
      S.Active_Find_Query := To_Unbounded_String ("AlphaBeta");
      S.Active_Replace_Text := To_Unbounded_String ("A-B");
      S.Active_Find_Stale := False;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);

      Assert_Line_Join_Coherent
        (S,
         "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         3, 1, 0, 1, 0, "Split line", True, False,
         Before_Clip, Before_Back, Before_Fwd,
         "Phase 398 split selection/find/clipboard/navigation boundaries");
      Assert (S.Active_Find_Query = To_Unbounded_String ("AlphaBeta"),
              "Phase 398 split must not mutate Find query text");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("A-B"),
              "Phase 398 split must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "Phase 398 split must invalidate active Find ranges through canonical text-edit hook");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 398 copy after split must observe cleared selection and preserve clipboard text");

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "Phase 398 render snapshot must not mutate split text");
      Assert (R.Primary_Caret_Row = 1 and then R.Primary_Caret_Col = 0,
              "Phase 398 render snapshot caret must reflect normalized split caret");
      Assert (R.Selection_Count = 0,
              "Phase 398 render snapshot must not expose stale cleared split selection");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 398 render/copy after split must not mutate navigation history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "AlphaBeta" & ASCII.LF & "Gamma",
         "Phase 398 undo after split restores exact text before selection split");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 398 undo after split leaves redo available");
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer) + 20));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Message_Text (S) = "Could not split line",
              "Phase 398 invalid injected caret split must fail deterministically");
      Assert_Buffer_Text
        (S, To_String (Before_Text),
         "Phase 398 failed invalid-caret split must not mutate text");
      Assert_Caret_Row_Col
        (S, 1, 5,
         "Phase 398 failed invalid-caret split clamps caret to canonical EOF");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "Phase 398 failed invalid-caret split must preserve dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "Phase 398 failed invalid-caret split must preserve undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 398 failed invalid-caret split must preserve redo stack");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 398 failed invalid-caret split must preserve clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 398 failed invalid-caret split must preserve navigation history");
   end Test_Phase398_Line_Split_Selection_Find_Clipboard_Navigation_And_Render;


   procedure Test_Phase398_Line_Split_Mixed_Current_Line_Command_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "Phase 398 split creates one canonical logical boundary before join");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta Gamma",
         "Phase 398 split then join follows join separator policy and is not a semantic inverse");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "Phase 398 undo mixed split/join restores exact pre-join split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta Gamma",
         "Phase 398 redo mixed split/join restores exact joined text");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "  AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 2);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, "  " & ASCII.LF & "AlphaBeta",
         "Phase 398 split inside leading whitespace does not auto-indent or copy indentation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert_Buffer_Text
        (S, "  " & ASCII.LF & "  AlphaBeta",
         "Phase 398 indent after split affects caret's new logical line only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "  " & ASCII.LF & "AlphaBeta",
         "Phase 398 undo indent after split restores exact split text");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "-- AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 3);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, "-- " & ASCII.LF & "AlphaBeta",
         "Phase 398 split treats comment markers as plain text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert_Buffer_Text
        (S, "-- " & ASCII.LF & "-- AlphaBeta",
         "Phase 398 toggle comment after split operates on caret's new logical line only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "-- " & ASCII.LF & "AlphaBeta",
         "Phase 398 undo comment after split restores exact split text");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Top" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 3)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "Mid" & ASCII.LF & "Tail" & ASCII.LF & "Bottom",
         "Phase 398 split after line editing setup uses logical line text only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "Mid" & ASCII.LF & "Tail" & ASCII.LF & "Tail" & ASCII.LF & "Bottom",
         "Phase 398 duplicate-line after split uses post-split current logical line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom",
         "Phase 398 mixed line-edit undo chain restores exact original text");
   end Test_Phase398_Line_Split_Mixed_Current_Line_Command_Workflows;


   procedure Test_Phase398_Line_Split_Active_Buffer_And_Persistence_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      A_Id           : Editor.Buffers.Buffer_Id;
      B_Id           : Editor.Buffers.Buffer_Id;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Availability   : Editor.Commands.Command_Availability;
      Before_Text    : Unbounded_String;
      Before_Caret   : Cursor_Index := 0;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "GammaDelta");
      Set_Caret (S, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, "Gamma" & ASCII.LF & "Delta",
         "Phase 398 split mutates only active buffer B");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 398 active buffer split creates one active-buffer undo entry");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "Phase 398 inactive buffer A remains unchanged by buffer B split");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 398 inactive buffer A does not inherit buffer B split undo entry");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "Phase 398 buffer A split operates independently after switch");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text
        (S, "Gamma" & ASCII.LF & "Delta",
         "Phase 398 switching back preserves buffer B split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "GammaDelta",
         "Phase 398 undo in buffer B affects only buffer B split entry");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "Phase 398 buffer B undo must not mutate buffer A split text");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "Phase 398 split and undo must not activate another buffer");

      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Editor.Commands.Is_Available (Availability),
              "Phase 398 split availability should be available with active buffer and caret");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "Phase 398 availability must not mutate buffer text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "Phase 398 availability must not move caret");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 398 availability must not mutate undo/redo stacks");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "last split") = 0
         and then Index (Summary, "split line") = 0
         and then Index (Summary, "split column") = 0
         and then Index (Summary, "split boundary") = 0
         and then Index (Summary, "smart newline") = 0
         and then Index (Summary, "auto-indent") = 0
         and then Index (Summary, "language-aware split") = 0,
         "Phase 398 workspace persistence must exclude Line Split transient state/settings");
   end Test_Phase398_Line_Split_Active_Buffer_And_Persistence_Boundaries;


   procedure Test_Phase399_Line_Split_Workflow_Position_And_Boundary_Matrices
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;

      procedure Check
        (Input        : String;
         Caret        : Cursor_Index;
         Expected     : String;
         Expected_Row : Natural;
         Why          : String)
      is
         Before_Back         : Natural := 0;
         Before_Fwd          : Natural := 0;
         Expected_Line_Count : Natural := 1;
      begin
         for Ch of Expected loop
            if Ch = ASCII.LF then
               Expected_Line_Count := Expected_Line_Count + 1;
            end if;
         end loop;
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Input);
         Editor.State.Set_Dirty (S, False);
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.Clipboard.Set_Text (To_Unbounded_String ("MATRIX-CLIP"));
         Set_Caret (S, Caret);
         Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
         Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Line_Split_At_Caret);

         Assert_Line_Join_Coherent
           (S, Expected, Expected_Line_Count, Expected_Row, 0,
            1, 0, "Split line", True, False,
            To_Unbounded_String ("MATRIX-CLIP"), Before_Back, Before_Fwd,
            Why);

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert_Buffer_Text (S, Input, Why & " undo exact text");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
                 Why & ": undo leaves redo entry");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert_Buffer_Text (S, Expected, Why & " redo exact text");
      end Check;
   begin
      Check ("Alpha", 0, ASCII.LF & "Alpha", 1,
             "Phase 399 position matrix line start");
      Check ("AlphaBeta", 5, "Alpha" & ASCII.LF & "Beta", 1,
             "Phase 399 position matrix middle");
      Check ("Alpha", 5, "Alpha" & ASCII.LF, 1,
             "Phase 399 position matrix line end");
      Check ("  Alpha", 2, "  " & ASCII.LF & "Alpha", 1,
             "Phase 399 position matrix inside leading spaces");
      Check ("Alpha  Beta", 7, "Alpha  " & ASCII.LF & "Beta", 1,
             "Phase 399 position matrix trailing spaces before suffix");
      Check (ASCII.HT & "AlphaBeta", 6,
             ASCII.HT & "Alpha" & ASCII.LF & "Beta", 1,
             "Phase 399 position matrix tab-leading text");
      Check ("   ", 3, "   " & ASCII.LF, 1,
             "Phase 399 whitespace-only line end");
      Check ("", 0, String'(1 => ASCII.LF), 1,
             "Phase 399 empty buffer frozen as two-empty-lines boundary");
      Check ("A" & ASCII.LF & "BC" & ASCII.LF & "D", 4,
             "A" & ASCII.LF & "B" & ASCII.LF & "C" & ASCII.LF & "D", 2,
             "Phase 399 middle logical line split only");
      Check ("A" & ASCII.LF & "B" & ASCII.LF & "C", 2,
             "A" & ASCII.LF & ASCII.LF & "B" & ASCII.LF & "C", 2,
             "Phase 399 middle line start split");
      Check ("A" & ASCII.LF & "B" & ASCII.LF & "C", 3,
             "A" & ASCII.LF & "B" & ASCII.LF & ASCII.LF & "C", 2,
             "Phase 399 middle line end split before boundary");
      Check ("A" & ASCII.LF & "B", 3,
             "A" & ASCII.LF & "B" & ASCII.LF, 2,
             "Phase 399 EOF split appends one canonical boundary");
   end Test_Phase399_Line_Split_Workflow_Position_And_Boundary_Matrices;


   procedure Test_Phase399_Line_Split_Undo_Redo_Dirty_Find_Clipboard_Navigation_Render
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      R             : Editor.Render_Model.Render_Snapshot;
      Before_Clip   : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Back   : Natural := 0;
      Before_Fwd    : Natural := 0;
      Before_Text   : Unbounded_String;
      Before_Dirty  : Boolean := False;
      Before_Undo   : Natural := 0;
      Before_Redo   : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Set_Primary_Selection (S, 0, 5);
      S.Active_Find_Query := To_Unbounded_String ("AlphaBeta");
      S.Active_Replace_Text := To_Unbounded_String ("Alpha-Beta");
      S.Active_Find_Stale := False;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);

      Assert_Line_Join_Coherent
        (S,
         "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         3, 1, 0, 1, 0, "Split line", True, False,
         Before_Clip, Before_Back, Before_Fwd,
         "Phase 399 split selection/find/clipboard/navigation coherent result");
      Assert (S.Active_Find_Query = To_Unbounded_String ("AlphaBeta"),
              "Phase 399 split must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Alpha-Beta"),
              "Phase 399 split must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "Phase 399 split must stale active Find ranges through text edit hook");

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "Phase 399 render snapshot must be side-effect-free after split");
      Assert (R.Primary_Caret_Row = 1 and then R.Primary_Caret_Col = 0,
              "Phase 399 render snapshot exposes normalized post-split caret");
      Assert (R.Selection_Count = 0,
              "Phase 399 render snapshot must not expose stale selection");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 399 copy after cleared split selection must preserve clipboard");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "AlphaBeta" & ASCII.LF & "Gamma",
         "Phase 399 undo restores exact pre-split text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 399 undo exposes one redo entry");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "Phase 399 redo restores exact post-split text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer) + 40));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Message_Text (S) = "Could not split line",
              "Phase 399 failed injected-caret split must report deterministic failure");
      Assert_Buffer_Text (S, To_String (Before_Text),
                          "Phase 399 failed split preserves text");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "Phase 399 failed split preserves dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "Phase 399 failed split preserves undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 399 failed split preserves redo stack");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 399 failed split preserves clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 399 failed split preserves navigation history");

      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 399 successful split after undo clears redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Message_Text (S) = "No edits to redo",
              "Phase 399 redo after successful split reports empty redo stack");
   end Test_Phase399_Line_Split_Undo_Redo_Dirty_Find_Clipboard_Navigation_Render;


   procedure Test_Phase399_Line_Split_Mixed_Command_Coexistence_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
                          "Phase 399 split before join exact text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta Gamma",
                          "Phase 399 join after split follows separate join separator policy");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
                          "Phase 399 undo join restores split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "AlphaBeta" & ASCII.LF & "Gamma",
                          "Phase 399 undo split restores original text");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Top" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 3)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "MidTail" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom",
         "Phase 399 duplicate-line setup exact text");
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 3)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "Mid" & ASCII.LF & "Tail" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom",
         "Phase 399 split after duplicate uses current logical line only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "Mid" & ASCII.LF & "MidTail" & ASCII.LF & "Tail" & ASCII.LF & "Bottom",
         "Phase 399 move-down after split uses post-split current line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "MidTail" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom",
         "Phase 399 undo mixed line-edit/split chain exact text");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "  AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "  " & ASCII.LF & "AlphaBeta",
                          "Phase 399 split inside indentation preserves sides exactly");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert_Buffer_Text (S, "  " & ASCII.LF & "  AlphaBeta",
                          "Phase 399 indent after split affects caret line only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert_Buffer_Text (S, "  " & ASCII.LF & "AlphaBeta",
                          "Phase 399 outdent after split leaves unindented caret line unchanged");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "-- AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "-- " & ASCII.LF & "AlphaBeta",
                          "Phase 399 split treats comment marker as plain text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert_Buffer_Text (S, "-- " & ASCII.LF & "-- AlphaBeta",
                          "Phase 399 toggle comment after split owns comment marker behavior");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert_Buffer_Text (S, "-- " & ASCII.LF & "AlphaBeta",
                          "Phase 399 uncomment after split does not infer marker across boundary");
   end Test_Phase399_Line_Split_Mixed_Command_Coexistence_Workflows;


   procedure Test_Phase399_Line_Split_Active_Buffer_Routes_Features_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      A_Id           : Editor.Buffers.Buffer_Id;
      B_Id           : Editor.Buffers.Buffer_Id;
      Candidates     : Editor.Commands.Command_Descriptor_Vectors.Vector;
      Split_Count    : Natural := 0;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Before_Text    : Unbounded_String;
      Before_Caret   : Cursor_Index := 0;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Availability   : Editor.Commands.Command_Availability;
      Found          : Boolean := False;
      Id             : Editor.Commands.Command_Id := Editor.Commands.No_Command;

      procedure Assert_Not_Exposed (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert ((not Found) and then Id = Editor.Commands.No_Command,
                 "Phase 399 non-goal Line Split command must not be exposed: " & Name);
      end Assert_Not_Exposed;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "GammaDelta");
      Set_Caret (S, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "Gamma" & ASCII.LF & "Delta",
                          "Phase 399 split mutates active buffer B only");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text (S, "AlphaBeta",
                          "Phase 399 inactive buffer A stays unchanged after B split");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 399 inactive buffer A has no inherited split undo entry");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta",
                          "Phase 399 buffer A split is independent");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text (S, "Gamma" & ASCII.LF & "Delta",
                          "Phase 399 buffer B retains its own split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "GammaDelta",
                          "Phase 399 undo in buffer B affects only buffer B");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "FeatureAlphaBeta" & ASCII.LF & "Tail");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 7);
      S.Active_Find_Query := To_Unbounded_String ("Feature");
      S.Active_Replace_Text := To_Unbounded_String ("ReplaceSeed");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("FEATURE-CLIP"));
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Filtered_Commands (Candidates);
      for C of Candidates loop
         if C.Id = Editor.Commands.Command_Line_Split_At_Caret then
            Split_Count := Split_Count + 1;
         end if;
      end loop;
      Assert (Split_Count = 1,
              "Phase 399 command palette projects exactly one split-at-caret command");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "Phase 399 command palette projection must not split text");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Editor.Commands.Is_Available (Availability),
              "Phase 399 split availability available with active buffer/caret");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "Phase 399 availability must not mutate text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "Phase 399 availability must not move caret");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 399 availability must not mutate history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "Feature" & ASCII.LF & "AlphaBeta" & ASCII.LF & "Tail",
                          "Phase 399 feature-populated split exact text");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Feature"),
              "Phase 399 split does not mutate Find query in feature-populated state");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("ReplaceSeed"),
              "Phase 399 split does not mutate Replace text in feature-populated state");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("FEATURE-CLIP"),
              "Phase 399 split does not mutate clipboard in feature-populated state");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "last split") = 0
         and then Index (Summary, "split line") = 0
         and then Index (Summary, "split column") = 0
         and then Index (Summary, "split boundary") = 0
         and then Index (Summary, "split availability") = 0
         and then Index (Summary, "smart newline") = 0
         and then Index (Summary, "auto-indent") = 0
         and then Index (Summary, "language-aware split") = 0
         and then Index (Summary, "formatting split") = 0,
         "Phase 399 workspace persistence must exclude Line Split transient state/settings");

      Assert_Not_Exposed ("edit.line.split-selection");
      Assert_Not_Exposed ("edit.line.split-all");
      Assert_Not_Exposed ("edit.line.split-paragraph");
      Assert_Not_Exposed ("edit.paragraph.reflow");
      Assert_Not_Exposed ("edit.format.document");
      Assert_Not_Exposed ("edit.format.selection");
      Assert_Not_Exposed ("edit.split.smart");
      Assert_Not_Exposed ("edit.split.language-aware");
      Assert_Not_Exposed ("edit.newline.auto-indent");
      Assert_Not_Exposed ("edit.newline.smart");
   end Test_Phase399_Line_Split_Active_Buffer_Routes_Features_And_Persistence;


   procedure Test_Phase399_Completeness_Selection_Caret_Only_And_Followups
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Clip : constant Unbounded_String := To_Unbounded_String ("SEL-CLIP");

      procedure Check
        (Input    : String;
         Anchor   : Cursor_Index;
         Pos      : Cursor_Index;
         Expected : String;
         Why      : String)
      is
      begin
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Input);
         Editor.State.Set_Dirty (S, False);
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.Clipboard.Set_Text (Before_Clip);
         --  The caret endpoint is the operative split location even when the
         --  active selection range lies before/after it or is reversed.
         Set_Primary_Selection (S, Anchor, Pos);

         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Line_Split_At_Caret);

         Assert_Buffer_Text (S, Expected, Why & " exact caret-only split text");
         Assert (not Editor.Selection.Has_Selection (S),
                 Why & ": successful split must collapse/clear selection");
         Assert (Editor.Clipboard.Get_Text = Before_Clip,
                 Why & ": line split must not mutate clipboard");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": text-changing split creates one undo entry");
         Assert (Message_Text (S) = "Split line",
                 Why & ": one primary split message");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
         Assert (Editor.Clipboard.Get_Text = Before_Clip,
                 Why & ": copy after cleared selection leaves clipboard owned by prior command");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert_Buffer_Text (S, Input, Why & " undo restores exact selected input text");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
                 Why & ": undo exposes redo for caret-only split");
      end Check;
   begin
      Check ("AlphaBeta", 0, 5,
             "Alpha" & ASCII.LF & "Beta",
             "Phase 399 selection before caret");
      Check ("AlphaBeta", 9, 5,
             "Alpha" & ASCII.LF & "Beta",
             "Phase 399 reversed selection after caret");
      Check ("AlphaBeta", 2, 8,
             "AlphaBet" & ASCII.LF & "a",
             "Phase 399 forward selection ending at caret");
      Check ("AlphaBeta", 8, 2,
             "Al" & ASCII.LF & "phaBeta",
             "Phase 399 backward selection ending at caret");
      Check ("One" & ASCII.LF & "AlphaBeta" & ASCII.LF & "Two",
             0,
             9,
             "One" & ASCII.LF & "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Two",
             "Phase 399 multi-line selection still splits caret line only");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "WordAlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Set_Primary_Selection (S, 0, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "Word" & ASCII.LF & "AlphaBeta",
                          "Phase 399 current-word selection does not replace selected word");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 399 current-word selection is cleared by successful split mutation");
   end Test_Phase399_Completeness_Selection_Caret_Only_And_Followups;


   procedure Test_Phase399_Completeness_No_Buffer_No_Caret_And_Routed_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      After      : Editor.State.State_Type;
      Avail      : Editor.Commands.Command_Availability;
      Before_Clip : constant Unbounded_String := To_Unbounded_String ("ROUTE-CLIP");
      Chord      : constant Editor.Keybindings.Key_Chord :=
        Editor.Keybindings.Key_Chord'
          (Key       => Editor.Keybindings.Key_N,
           Modifiers =>
             (Ctrl  => True,
              Shift => True,
              Alt   => True,
              Meta  => False));
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No active buffer.",
              "Phase 399 no-active-buffer availability is deterministic");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Message_Text (S) = "No active buffer.",
              "Phase 399 no-active-buffer split reports one canonical message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0
              and then Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 399 no-active-buffer split mutates no history");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 399 no-active-buffer split does not touch clipboard");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      S.Carets.Clear;
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No caret location",
              "Phase 399 no-caret availability is deterministic");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "AlphaBeta",
                          "Phase 399 no-caret split preserves buffer text");
      Assert (Message_Text (S) = "No caret location",
              "Phase 399 no-caret split reports one canonical message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0
              and then Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 399 no-caret split mutates no history");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 399 no-caret split does not mark buffer dirty");

      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "RouteAlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Text_Buffer.UTF8_Text (After.Buffer) =
              "Route" & ASCII.LF & "AlphaBeta",
              "Phase 399 routed keybinding must use canonical Executor split path");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 399 routed keybinding split creates one undo entry");
      Assert (Message_Text (After) = "Split line",
              "Phase 399 routed keybinding emits canonical split message");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase399_Completeness_No_Buffer_No_Caret_And_Routed_Input;


   procedure Test_Phase399_Completeness_Read_Only_And_Persistence_Surfaces
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      R              : Editor.Render_Model.Render_Snapshot;
      Candidates     : Editor.Commands.Command_Descriptor_Vectors.Vector;
      Before_Text    : constant String := "ReadOnlyAlphaBeta";
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("READONLY-CLIP");
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Set_Primary_Selection (S, 0, 4);
      declare
         C : Editor.Cursors.Caret_State := S.Carets (S.Carets.First_Index);
      begin
         C.Pos := Cursor_Index (Text_Buffer.Length (S.Buffer) + 25);
         S.Carets.Replace_Element (S.Carets.First_Index, C);
      end;
      S.Active_Find_Query := To_Unbounded_String ("Alpha");
      S.Active_Replace_Text := To_Unbounded_String ("Omega");
      S.Active_Find_Stale := False;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text (S, Before_Text,
                          "Phase 399 render snapshot must not repair stale caret by splitting");
      Assert (R.Length = Text_Buffer.Length (S.Buffer),
              "Phase 399 render snapshot length derives from unchanged canonical buffer");
      Assert (Editor.Selection.Has_Selection (S),
              "Phase 399 render snapshot must not clear selection before split command");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 399 render snapshot must not mutate clipboard");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 399 render snapshot must not mutate history");

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Filtered_Commands (Candidates);
      Assert (Candidates.Length > 0,
              "Phase 399 command palette projection returns command candidates");
      Assert_Buffer_Text (S, Before_Text,
                          "Phase 399 command palette projection must not split or repair text");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Alpha")
              and then S.Active_Replace_Text = To_Unbounded_String ("Omega")
              and then not S.Active_Find_Stale,
              "Phase 399 read-only projections must not mutate Find/Replace state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, Before_Text,
                          "Phase 399 stale-caret split failure preserves text");
      Assert (Message_Text (S) = "Could not split line",
              "Phase 399 stale-caret split failure emits deterministic one-message failure");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 399 stale-caret split failure preserves history");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 399 stale-caret split failure preserves clipboard");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "split-at-caret") = 0
         and then Index (Summary, "last split") = 0
         and then Index (Summary, "split line") = 0
         and then Index (Summary, "split column") = 0
         and then Index (Summary, "smart newline") = 0
         and then Index (Summary, "auto-indent") = 0
         and then Index (Summary, "language-aware split") = 0,
         "Phase 399 persistence summary excludes split transient state after failure");
   end Test_Phase399_Completeness_Read_Only_And_Persistence_Surfaces;


procedure Test_Phase400_Line_Split_Canonical_Behavior_And_State_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      R              : Editor.Render_Model.Render_Snapshot;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("PHASE400-CLIP");
      Before_Redo    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "  -- AlphaBeta" & ASCII.LF & "Tail");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Primary_Selection (S, 2, 10);
      Editor.Clipboard.Set_Text (Before_Clip);
      S.Active_Find_Query := To_Unbounded_String ("Alpha");
      S.Active_Replace_Text := To_Unbounded_String ("Omega");
      S.Active_Find_Stale := False;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);

      Assert_Buffer_Text
        (S,
         "  -- Alph" & ASCII.LF & "aBeta" & ASCII.LF & "Tail",
         "Phase 400 split must insert exactly one canonical boundary at the caret");
      Assert_Caret_Row_Col (S, 1, 0,
                            "Phase 400 split caret must normalize to new line start");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 400 successful split must clear the stale active selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 400 split must create exactly one canonical undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 400 split must not create custom redo state");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 400 split must update dirty state through canonical edit policy");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Alpha"),
              "Phase 400 split must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Omega"),
              "Phase 400 split must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "Phase 400 split must use canonical Find/Replace invalidation");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 400 split must not read or mutate Clipboard state");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "Phase 400 split must not record Navigation History");
      Assert (Message_Text (S) = "Split line",
              "Phase 400 split must emit the canonical one primary message");

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text
        (S,
         "  -- Alph" & ASCII.LF & "aBeta" & ASCII.LF & "Tail",
         "Phase 400 render snapshot must be read-only over canonical buffer text");
      Assert (R.Primary_Caret_Row = 1 and then R.Primary_Caret_Col = 0,
              "Phase 400 render caret must derive from canonical caret state only");
      Assert (R.Selection_Count = 0,
              "Phase 400 render snapshot must not expose stale split selection state");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "split-at-caret") = 0
         and then Index (Summary, "last split") = 0
         and then Index (Summary, "split line") = 0
         and then Index (Summary, "split column") = 0
         and then Index (Summary, "split boundary") = 0
         and then Index (Summary, "split availability") = 0
         and then Index (Summary, "smart newline") = 0
         and then Index (Summary, "auto-indent") = 0
         and then Index (Summary, "language-aware split") = 0
         and then Index (Summary, "formatting split") = 0,
         "Phase 400 workspace persistence must exclude canonical and removed Line Split state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "  -- AlphaBeta" & ASCII.LF & "Tail",
                          "Phase 400 undo restores captured before text without replaying split");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S,
         "  -- Alph" & ASCII.LF & "aBeta" & ASCII.LF & "Tail",
         "Phase 400 redo restores captured after text without recomputing split policy");
   end Test_Phase400_Line_Split_Canonical_Behavior_And_State_Boundaries;


   procedure Test_Phase400_Line_Split_Failure_Read_Only_And_Ordinary_Newline_Separation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Text : Unbounded_String;
      Before_Clip : constant Unbounded_String := To_Unbounded_String ("FAIL-CLIP");
      Availability : Editor.Commands.Command_Availability;
      Before_Undo : Natural := 0;
      Before_Redo : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Set_Caret (S, 5);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Editor.Commands.Is_Available (Availability),
              "Phase 400 canonical Line Split availability should be available before split");
      Assert_Buffer_Text (S, To_String (Before_Text),
                          "Phase 400 availability must not mutate text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 400 availability must not mutate Undo/Redo stacks");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Insert_Newline);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta",
                          "Phase 400 ordinary Insert Newline remains separate but uses canonical text edit semantics");
      Assert (Message_Text (S) /= "Split line",
              "Phase 400 ordinary newline insertion must not report the Line Split command message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 400 ordinary newline insertion is one normal edit entry");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "StaleAlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Set_Primary_Selection (S, 0, 5);
      declare
         C : Editor.Cursors.Caret_State := S.Carets (S.Carets.First_Index);
      begin
         C.Pos := Cursor_Index (Text_Buffer.Length (S.Buffer) + 50);
         S.Carets.Replace_Element (S.Carets.First_Index, C);
      end;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "StaleAlphaBeta",
                          "Phase 400 failed split must preserve buffer text");
      Assert (Message_Text (S) = "Could not split line",
              "Phase 400 failed split must emit canonical failure message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 400 failed split must not mutate history stacks");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 400 failed split must not mutate Clipboard state");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 400 failed split must not dirty the buffer");
      Assert (S.Active_Find_Query = Null_Unbounded_String
              and then S.Active_Replace_Text = Null_Unbounded_String,
              "Phase 400 failed split must not synthesize Find/Replace state");
   end Test_Phase400_Line_Split_Failure_Read_Only_And_Ordinary_Newline_Separation;




   procedure Test_Phase401_Word_Delete_Command_Descriptors_And_Routes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Chord : constant Editor.Keybindings.Key_Chord :=
        Editor.Keybindings.Key_Chord'
          (Key       => Editor.Keybindings.Key_Backspace,
           Modifiers =>
             (Ctrl  => True,
              Shift => True,
              Alt   => False,
              Meta  => False));
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Word_Delete_Previous) =
         "edit.word.delete-previous",
         "Phase 401 previous-word delete stable name mismatch");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Word_Delete_Next) =
         "edit.word.delete-next",
         "Phase 401 next-word delete stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Word_Delete_Previous).Category =
         Editor.Commands.Edit_Category,
         "Phase 401 previous-word delete must be an Edit command");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Word_Delete_Next).Visibility =
         Editor.Commands.Palette_Command,
         "Phase 401 next-word delete must be palette visible");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Word_Delete_Previous)
         and then Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Word_Delete_Next),
         "Phase 401 word delete commands must be bindable");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.word.delete-previous", Found);
      Assert (Found and then Id = Editor.Commands.Command_Word_Delete_Previous,
              "Phase 401 previous-word stable name lookup mismatch");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.word.delete-next", Found);
      Assert (Found and then Id = Editor.Commands.Command_Word_Delete_Next,
              "Phase 401 next-word stable name lookup mismatch");

      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Word_Delete_Previous);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Route Alpha");
      Set_Caret (S, 11);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text (After, "Route ",
                          "Phase 401 Input_Bridge word delete must route through Executor");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 401 routed word delete must create one undo entry");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase401_Word_Delete_Command_Descriptors_And_Routes;

   procedure Test_Phase401_Delete_Previous_Word_Boundaries_Selection_And_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Redo_Count : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha   Beta");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 12);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Alpha   ",
                          "Phase 401 delete-previous must delete the preceding word span");
      Assert (Natural (S.Carets (S.Carets.First_Index).Pos) = 8,
              "Phase 401 delete-previous caret must move to deleted range start");
      Assert (Message_Text (S) = "Deleted previous word",
              "Phase 401 delete-previous success message mismatch");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 401 delete-previous must dirty changed clean buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 401 delete-previous must create one undo entry");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 401 delete-previous must not mutate clipboard");
      Assert_Navigation_Counts (S, 0, 0,
                                "Phase 401 delete-previous must not record navigation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha   Beta",
                          "Phase 401 undo after delete-previous must restore exact text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha   ",
                          "Phase 401 redo after delete-previous must restore edited text");

      Editor.State.Load_Text (S, "Alpha   Beta");
      Set_Caret (S, 8);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Beta",
                          "Phase 401 delete-previous after whitespace must delete whitespace plus prior word");

      Editor.State.Load_Text (S, "Alpha...Beta");
      Set_Caret (S, 8);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "AlphaBeta",
                          "Phase 401 delete-previous must delete punctuation spans as plain text");

      Editor.State.Load_Text (S, "Alpha_Beta123");
      Set_Caret (S, 13);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "",
                          "Phase 401 delete-previous word class must include underscore and digits");

      Editor.State.Load_Text (S, "One" & ASCII.LF & "Two");
      Set_Caret (S, 4);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Two",
                          "Phase 401 delete-previous must treat line boundary as whitespace");

      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Primary_Selection (S, 0, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, " Beta",
                          "Phase 401 delete-previous must operate at caret, not consume selection");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 401 successful delete-previous must collapse selection");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Message_Text (S) = "Nothing to delete",
              "Phase 401 delete-previous buffer-start no-op message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "Phase 401 delete-previous no-op must preserve redo stack");
   end Test_Phase401_Delete_Previous_Word_Boundaries_Selection_And_Undo;

   procedure Test_Phase401_Delete_Next_Word_Boundaries_No_Ops_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      No_Buffer  : Editor.State.State_Type;
      Avail      : Editor.Commands.Command_Availability;
      Snap       : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary    : Unbounded_String;
      Redo_Count : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha   Beta");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 0);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "   Beta",
                          "Phase 401 delete-next must delete the following word span");
      Assert (Natural (S.Carets (S.Carets.First_Index).Pos) = 0,
              "Phase 401 delete-next caret must remain at deletion start");
      Assert (Message_Text (S) = "Deleted next word",
              "Phase 401 delete-next success message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 401 delete-next must create one undo entry");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 401 delete-next must not mutate clipboard");

      Editor.State.Load_Text (S, "Alpha   Beta");
      Set_Caret (S, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha",
                          "Phase 401 delete-next after whitespace must delete whitespace plus next word");

      Editor.State.Load_Text (S, "...Alpha");
      Set_Caret (S, 0);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha",
                          "Phase 401 delete-next must delete punctuation spans as plain text");

      Editor.State.Load_Text (S, "Alpha_Beta123");
      Set_Caret (S, 0);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "",
                          "Phase 401 delete-next word class must include underscore and digits");

      Editor.State.Load_Text (S, "One" & ASCII.LF & "Two");
      Set_Caret (S, 3);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "One",
                          "Phase 401 delete-next must treat line boundary as whitespace");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert (Message_Text (S) = "Nothing to delete",
              "Phase 401 delete-next buffer-end no-op message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "Phase 401 delete-next no-op must preserve redo stack");

      S.Carets.Clear;
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No caret location",
              "Phase 401 no-caret availability must be deterministic");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert (Message_Text (S) = "No caret location",
              "Phase 401 no-caret execution message mismatch");

      Editor.State.Init (No_Buffer);
      Avail := Editor.Executor.Command_Availability
        (No_Buffer, Editor.Commands.Command_Word_Delete_Previous);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No active buffer.",
              "Phase 401 no-active-buffer availability must be deterministic");
      Editor.Executor.Execute_Command
        (No_Buffer, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "Phase 401 no-active-buffer execution message mismatch");

      Editor.State.Load_Text (S, "Persist Word");
      Set_Caret (S, 7);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snap));
      Assert
        (Index (Summary, "word delete") = 0
         and then Index (Summary, "deleted word") = 0
         and then Index (Summary, "word-boundary") = 0
         and then Index (Summary, "last word") = 0,
         "Phase 401 workspace persistence must exclude Word Delete transient state");
   end Test_Phase401_Delete_Next_Word_Boundaries_No_Ops_And_Persistence;


   procedure Test_Phase402_Delete_Previous_Word_Reliability_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;

      procedure Expect_Previous
        (Before         : String;
         Caret          : Cursor_Index;
         Expected       : String;
         Expected_Caret : Cursor_Index;
         Why            : String)
      is
      begin
         Editor.State.Load_Text (S, Before);
         Set_Caret (S, Caret);
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Word_Delete_Previous);
         Assert_Buffer_Text (S, Expected, Why);
         Assert (S.Carets (S.Carets.First_Index).Pos = Expected_Caret,
                 Why & ": caret mismatch");
         Assert (Message_Text (S) = "Deleted previous word",
                 Why & ": success message mismatch");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": text-changing delete must create one undo entry");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": text-changing delete must leave redo empty");
         Assert (not Editor.Selection.Has_Selection (S),
                 Why & ": successful word delete must collapse selection");
      end Expect_Previous;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));

      Expect_Previous ("Alpha", 5, "", 0,
                       "Phase 402 previous deletes simple trailing word");
      Expect_Previous ("Alpha Beta", 10, "Alpha ", 6,
                       "Phase 402 previous deletes trailing word after one space");
      Expect_Previous ("Alpha   Beta", 13, "Alpha   ", 8,
                       "Phase 402 previous preserves multiple spaces before trailing word");
      Expect_Previous ("Alpha   Beta", 8, "Beta", 0,
                       "Phase 402 previous deletes whitespace run plus prior word");
      Expect_Previous ("Alpha_Beta", 10, "", 0,
                       "Phase 402 previous treats underscore as word");
      Expect_Previous ("Alpha123", 8, "", 0,
                       "Phase 402 previous treats digits as word");
      Expect_Previous ("Alpha.", 6, "Alpha", 5,
                       "Phase 402 previous deletes single punctuation");
      Expect_Previous ("Alpha...", 8, "Alpha", 5,
                       "Phase 402 previous deletes punctuation run");
      Expect_Previous ("Al" & String'(1 => ASCII.HT) & "pha", 3,
                       "pha", 0,
                       "Phase 402 previous treats tab as whitespace plus prior word");
      Expect_Previous ("Al" & Character'Val (16#C3#) & Character'Val (16#A9#) & "pha", 3,
                       "Alpha", 2,
                       "Phase 402 previous treats non-ASCII bytes as other text");
      Expect_Previous ("Alpha", 2, "pha", 0,
                       "Phase 402 previous inside word deletes prefix span");
      Expect_Previous ("Alpha  " & "  Beta", 7, "  Beta", 0,
                       "Phase 402 previous inside whitespace run is deterministic");
      Expect_Previous ("Alpha.." & "..Beta", 7, "Alpha..Beta", 5,
                       "Phase 402 previous inside punctuation run is deterministic");
      Expect_Previous ("Alpha" & ASCII.LF & "Beta", 6, "Beta", 0,
                       "Phase 402 previous crosses canonical line boundary as whitespace");
      Expect_Previous ("Alpha" & ASCII.LF & ASCII.LF & "Beta", 7, "Beta", 0,
                       "Phase 402 previous crosses blank line boundary run as whitespace");

      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, 0);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Alpha",
                          "Phase 402 previous at buffer start must no-op");
      Assert (Message_Text (S) = "Nothing to delete",
              "Phase 402 previous no-op message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 402 previous no-op must not create undo");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 402 previous matrix must not mutate clipboard");
   end Test_Phase402_Delete_Previous_Word_Reliability_Matrix;

   procedure Test_Phase402_Delete_Next_Word_Reliability_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;

      procedure Expect_Next
        (Before         : String;
         Caret          : Cursor_Index;
         Expected       : String;
         Expected_Caret : Cursor_Index;
         Why            : String)
      is
      begin
         Editor.State.Load_Text (S, Before);
         Set_Caret (S, Caret);
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Word_Delete_Next);
         Assert_Buffer_Text (S, Expected, Why);
         Assert (S.Carets (S.Carets.First_Index).Pos = Expected_Caret,
                 Why & ": caret mismatch");
         Assert (Message_Text (S) = "Deleted next word",
                 Why & ": success message mismatch");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": text-changing delete must create one undo entry");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": text-changing delete must leave redo empty");
      end Expect_Next;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));

      Expect_Next ("Alpha", 0, "", 0,
                   "Phase 402 next deletes simple leading word");
      Expect_Next ("Alpha Beta", 0, " Beta", 0,
                   "Phase 402 next preserves following separator after first word");
      Expect_Next ("Alpha   Beta", 5, "Alpha", 5,
                   "Phase 402 next deletes whitespace run plus following word");
      Expect_Next ("Alpha_Beta", 0, "", 0,
                   "Phase 402 next treats underscore as word");
      Expect_Next ("Alpha123", 0, "", 0,
                   "Phase 402 next treats digits as word");
      Expect_Next ("...Alpha", 0, "Alpha", 0,
                   "Phase 402 next deletes punctuation run");
      Expect_Next (", Alpha", 0, " Alpha", 0,
                   "Phase 402 next deletes single punctuation");
      Expect_Next ("Al" & String'(1 => ASCII.HT) & "pha", 2, "Al", 2,
                   "Phase 402 next treats tab as whitespace plus following word");
      Expect_Next ("Alpha", 2, "Al", 2,
                   "Phase 402 next inside word deletes suffix span");
      Expect_Next ("Alpha  " & "  Beta", 7, "Alpha  ", 7,
                   "Phase 402 next inside whitespace run is deterministic");
      Expect_Next ("Alpha.." & "..Beta", 7, "Alpha..Beta", 7,
                   "Phase 402 next inside punctuation run is deterministic");
      Expect_Next ("Alpha" & ASCII.LF & "Beta", 5, "Alpha", 5,
                   "Phase 402 next crosses canonical line boundary as whitespace");
      Expect_Next ("Alpha" & ASCII.LF & ASCII.LF & "Beta", 5, "Alpha", 5,
                   "Phase 402 next crosses blank line boundary run as whitespace");

      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha",
                          "Phase 402 next at buffer end must no-op");
      Assert (Message_Text (S) = "Nothing to delete",
              "Phase 402 next no-op message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 402 next no-op must not create undo");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 402 next matrix must not mutate clipboard");
   end Test_Phase402_Delete_Next_Word_Reliability_Matrix;

   procedure Test_Phase402_Word_Delete_State_Integration_And_Read_Only_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Avail         : Editor.Commands.Command_Availability;
      Before_Text   : Unbounded_String;
      Before_Caret  : Cursor_Index := 0;
      Before_Undo   : Natural := 0;
      Before_Redo   : Natural := 0;
      Before_Dirty  : Boolean := False;
      Before_Stale  : Boolean := False;
      Before_Back   : Natural := 0;
      Before_Fwd    : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Beta");
      S.Active_Replace_Prompt := True;
      S.Active_Replace_Text := To_Unbounded_String ("REPL");
      Set_Primary_Selection (S, 0, 5);

      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Stale := S.Active_Find_Stale;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 402 word delete availability must remain available with buffer and caret");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 402 next word delete availability must remain available with buffer and caret");
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 402 render snapshot length must derive from canonical buffer text");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "Phase 402 render/availability must not mutate buffer text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "Phase 402 render/availability must not move caret");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 402 render/availability must not mutate undo/redo stacks");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "Phase 402 render/availability must not mutate dirty state");
      Assert (S.Active_Find_Stale = Before_Stale
              and then To_String (S.Active_Find_Query) = "Beta"
              and then To_String (S.Active_Replace_Text) = "REPL",
              "Phase 402 render/availability must not mutate Find/Replace state");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 402 render/availability must not mutate navigation history");

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha ",
                          "Phase 402 delete-next must remove exact active Find match text");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Phase 402 text-changing word delete must invalidate Find ranges");
      Assert (To_String (S.Active_Find_Query) = "Beta"
              and then To_String (S.Active_Replace_Text) = "REPL"
              and then S.Active_Replace_Prompt,
              "Phase 402 word delete must preserve Find query and Replace text");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "Phase 402 word delete must not mutate clipboard");
      Assert_Navigation_Counts (S, 0, 0,
                                "Phase 402 word delete must not record navigation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "Phase 402 undo must restore exact pre-delete text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 402 undo after word delete must make redo available");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Message_Text (S) = "Nothing to delete",
              "Phase 402 no-op after undo must report Nothing to delete");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 402 no-op after undo must preserve redo stack");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 402 successful word delete after undo must clear redo stack");
   end Test_Phase402_Word_Delete_State_Integration_And_Read_Only_Boundaries;

   procedure Test_Phase402_Word_Delete_Current_Line_Coexistence_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Snap    : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary : Unbounded_String;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta",
                          "Phase 402 split precondition must produce canonical line boundary");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Beta",
                          "Phase 402 word delete after split must use buffer text, not Line Join");
      Assert (Message_Text (S) = "Deleted previous word",
              "Phase 402 word delete after split message mismatch");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta",
                          "Phase 402 undo after mixed split/delete must restore split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Beta",
                          "Phase 402 redo after mixed split/delete must restore delete result");

      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Set_Caret (S, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Join_Next);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Message_Text (S) = "Deleted previous word",
              "Phase 402 word delete after join must still be a word-delete command");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 2,
              "Phase 402 mixed join/delete sequence must keep one undo entry per mutation");

      Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snap));
      Assert
        (Index (Summary, "word delete") = 0
         and then Index (Summary, "deleted word") = 0
         and then Index (Summary, "last word") = 0
         and then Index (Summary, "word-boundary") = 0,
         "Phase 402 workspace persistence must exclude Word Delete transient state");
   end Test_Phase402_Word_Delete_Current_Line_Coexistence_And_Persistence;



   procedure Test_Phase403_Word_Delete_Boundary_Transform_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha|", "|", "Alpha",
         "Phase 403 previous boundary simple word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha Beta|", "Alpha |", "Beta",
         "Phase 403 previous boundary trailing word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha   Beta|", "Alpha   |", "Beta",
         "Phase 403 previous boundary preserves whitespace before word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha   |Beta", "|Beta", "Alpha   ",
         "Phase 403 previous boundary deletes whitespace plus prior word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha_Beta|", "|", "Alpha_Beta",
         "Phase 403 previous boundary underscore word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha123|", "|", "Alpha123",
         "Phase 403 previous boundary digit word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha.|", "Alpha|", ".",
         "Phase 403 previous boundary punctuation");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha...|", "Alpha|", "...",
         "Phase 403 previous boundary punctuation run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha, Beta|", "Alpha, |", "Beta",
         "Phase 403 previous boundary mixed punctuation and word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Al|pha", "|pha", "Al",
         "Phase 403 previous boundary inside word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha  |  Beta", "|  Beta", "Alpha  ",
         "Phase 403 previous boundary inside whitespace run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha..|..Beta", "Alpha|..Beta", "..",
         "Phase 403 previous boundary inside punctuation run");

      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|Alpha", "|", "Alpha",
         "Phase 403 next boundary simple word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|Alpha Beta", "| Beta", "Alpha",
         "Phase 403 next boundary leading word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha |  Beta", "Alpha |", "  Beta",
         "Phase 403 next boundary whitespace plus word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|Alpha_Beta", "|", "Alpha_Beta",
         "Phase 403 next boundary underscore word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|Alpha123", "|", "Alpha123",
         "Phase 403 next boundary digit word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|...Alpha", "|Alpha", "...",
         "Phase 403 next boundary punctuation run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|, Alpha", "| Alpha", ",",
         "Phase 403 next boundary punctuation");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Al|pha", "Al|", "pha",
         "Phase 403 next boundary inside word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha  |  Beta", "Alpha  |", "  Beta",
         "Phase 403 next boundary inside whitespace run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha..|..Beta", "Alpha..|Beta", "..",
         "Phase 403 next boundary inside punctuation run");

      Assert_Word_Delete_No_Op
        (Word_Delete_Test_Previous, "|Alpha",
         "Phase 403 previous no-op at buffer start");
      Assert_Word_Delete_No_Op
        (Word_Delete_Test_Next, "Alpha|",
         "Phase 403 next no-op at buffer end");
   end Test_Phase403_Word_Delete_Boundary_Transform_Workflows;

   procedure Test_Phase403_Word_Delete_Cross_Line_Selection_Find_Clipboard
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      R            : Editor.Render_Model.Render_Snapshot;
      Before_Clip  : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Back  : Natural := 0;
      Before_Fwd   : Natural := 0;
   begin
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha" & ASCII.LF & "|Beta", "|Beta",
         "Alpha" & ASCII.LF,
         "Phase 403 previous crosses one line boundary as whitespace");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha|" & ASCII.LF & "Beta", "Alpha|",
         String'(1 => ASCII.LF) & "Beta",
         "Phase 403 next crosses one line boundary as whitespace");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha" & ASCII.LF & ASCII.LF & "|Beta", "|Beta",
         "Alpha" & ASCII.LF & ASCII.LF,
         "Phase 403 previous crosses blank line boundary run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha|" & ASCII.LF & ASCII.LF & "Beta", "Alpha|",
         String'(1 => ASCII.LF) & ASCII.LF & "Beta",
         "Phase 403 next crosses blank line boundary run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha" & ASCII.LF & "  |Beta", "|Beta",
         "Alpha" & ASCII.LF & "  ",
         "Phase 403 previous treats indentation as plain whitespace");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha|" & ASCII.LF & "  Beta", "Alpha|",
         String'(1 => ASCII.LF) & "  Beta",
         "Phase 403 next treats indentation as plain whitespace");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Beta");
      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "REPL");
      Set_Primary_Selection (S, 0, 5);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha  Gamma",
                          "Phase 403 delete-next removes exact Find match word");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Phase 403 text-changing Word Delete must invalidate computed Find ranges");
      Assert (To_String (S.Active_Find_Query) = "Beta"
              and then To_String (S.Active_Replace_Text) = "REPL"
              and then S.Active_Replace_Prompt,
              "Phase 403 Word Delete must preserve Find query and Replace text");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 403 successful Word Delete must collapse active selection");
      Assert (Editor.Clipboard.Has_Text
              and then Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 403 Word Delete must not copy deleted word into Clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 403 Word Delete must not record navigation history");
      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert (R.Length = Text_Buffer.Length (S.Buffer),
              "Phase 403 render snapshot after Word Delete must match canonical buffer length");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta Gamma",
                          "Phase 403 undo restores exact Find workflow text");
      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert (R.Length = Text_Buffer.Length (S.Buffer),
              "Phase 403 render snapshot after undo must match canonical buffer length");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha  Gamma",
                          "Phase 403 redo restores exact Find workflow text");

      Set_Caret (S, 0);
      S.Active_Find_Stale := False;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (not S.Active_Find_Stale,
              "Phase 403 no-op Word Delete must not invalidate Find/Replace state");
   end Test_Phase403_Word_Delete_Cross_Line_Selection_Find_Clipboard;

   procedure Test_Phase403_Word_Delete_Undo_Redo_Dirty_And_Current_Line_Coexistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Alpha ",
                          "Phase 403 dirty matrix delete-previous text");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 403 text-changing delete-previous must dirty clean buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 403 delete-previous must create one undo entry");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "Phase 403 undo after delete-previous restores baseline text");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 403 undo to saved baseline must clear dirty state");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha ",
                          "Phase 403 redo after delete-previous restores edited text");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 403 redo to edited text must restore dirty state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 403 no-op delete-previous after undo preserves redo stack");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 403 successful delete-previous after undo clears redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Message_Text (S) = "No edits to redo",
              "Phase 403 redo after successful Word Delete invalidation must be unavailable");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "AlphaBeta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Beta",
                          "Phase 403 split then delete-previous must delete by canonical text only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta",
                          "Phase 403 undo mixed split/delete restores split text");

      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Join_Next);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Natural (Editor.History.Undo_Stack.Length) = 2,
              "Phase 403 join/delete sequence must keep one undo entry per mutation");

      Editor.State.Load_Text (S, "  Alpha" & ASCII.LF & "Beta");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 2);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Indent_Increase);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Message_Text (S) = "Deleted previous word",
              "Phase 403 indent/delete mixed workflow must stay in Word Delete command path");

      Editor.State.Load_Text (S, "Alpha");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Toggle_Line_Comment);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Message_Text (S) = "Deleted previous word",
              "Phase 403 comment/delete mixed workflow must stay in Word Delete command path");
   end Test_Phase403_Word_Delete_Undo_Redo_Dirty_And_Current_Line_Coexistence;

   procedure Test_Phase403_Word_Delete_Active_Buffer_Routes_Features_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      A              : Editor.Buffers.Buffer_Id;
      B              : Editor.Buffers.Buffer_Id;
      Avail          : Editor.Commands.Command_Availability;
      Snap           : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Before_Text    : Unbounded_String;
      Before_Caret   : Cursor_Index := 0;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Before_Dirty   : Boolean := False;
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Chord          : constant Editor.Keybindings.Key_Chord :=
        Editor.Keybindings.Key_Chord'
          (Key       => Editor.Keybindings.Key_Delete,
           Modifiers =>
             (Ctrl  => True,
              Shift => True,
              Alt   => False,
              Meta  => False));
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Buffers.Ensure_Global_Registry (S);
      A := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "Gamma Delta");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Alpha ",
                          "Phase 403 active-buffer A delete text");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Buffer_Text (S, "Gamma Delta",
                          "Phase 403 active-buffer B must be isolated from A delete");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Gamma ",
                          "Phase 403 active-buffer B independent delete text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Gamma Delta",
                          "Phase 403 undo in B affects only B");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Buffer_Text (S, "Alpha ",
                          "Phase 403 returning to A preserves A delete result");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "Phase 403 undo in A affects only A");

      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 403 availability check must expose Word Delete with active buffer/caret");
      declare
         Candidates : Editor.Commands.Command_Descriptor_Vectors.Vector;
      begin
         Editor.Command_Palette.Reset;
         Editor.Command_Palette.Filtered_Commands (Candidates);
         Assert (Candidates.Length > 0,
                 "Phase 403 Command Palette projection must return candidates");
      end;
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text)
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo
              and then Editor.State.Is_Dirty (S) = Before_Dirty,
              "Phase 403 availability/palette projection must be side-effect-free");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 403 availability/palette must not mutate navigation history");

      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Word_Delete_Next);
      Set_Caret (S, 0);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      declare
         After : constant Editor.State.State_Type :=
           Editor.Input_Bridge.Get_State_For_Test;
      begin
         Assert_Buffer_Text (After, " Beta",
                             "Phase 403 Input_Bridge keybinding must route delete-next through Executor");
         Assert (Message_Text (After) = "Deleted next word",
                 "Phase 403 routed delete-next message mismatch");
      end;
      Editor.Keybindings.Reset_To_Defaults;

      Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snap));
      Assert
        (Index (Summary, "word delete") = 0
         and then Index (Summary, "deleted word") = 0
         and then Index (Summary, "last word") = 0
         and then Index (Summary, "last deleted") = 0
         and then Index (Summary, "word-boundary") = 0
         and then Index (Summary, "semantic word") = 0,
         "Phase 403 workspace persistence must exclude Word Delete transient state and policy");
   end Test_Phase403_Word_Delete_Active_Buffer_Routes_Features_And_Persistence;


   procedure Test_Phase404_Word_Delete_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found          : Boolean := False;
      Id             : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Previous_Count : Natural := 0;
      Next_Count     : Natural := 0;
      Palette_Prev   : Natural := 0;
      Palette_Next   : Natural := 0;
      Candidates     : Editor.Commands.Command_Descriptor_Vectors.Vector;
      Path           : constant String := "/tmp/editor-phase404-canonical-word-delete-keybindings";
      File           : Ada.Text_IO.File_Type;
      Config         : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status         : Editor.Keybinding_Config.Keybinding_Config_Status;
      Chord          : Editor.Keybindings.Key_Chord;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.word.delete-previous", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Word_Delete_Previous,
         "Phase 404 previous Word Delete command must resolve through canonical stable name");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.word.delete-next", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Word_Delete_Next,
         "Phase 404 next Word Delete command must resolve through canonical stable name");

      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            C    : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
            Name : constant String := Editor.Commands.Stable_Command_Name (C);
         begin
            if C = Editor.Commands.Command_Word_Delete_Previous then
               Previous_Count := Previous_Count + 1;
               Assert (Name = "edit.word.delete-previous",
                       "Phase 404 previous Word Delete registry stable name mismatch");
            elsif C = Editor.Commands.Command_Word_Delete_Next then
               Next_Count := Next_Count + 1;
               Assert (Name = "edit.word.delete-next",
                       "Phase 404 next Word Delete registry stable name mismatch");
            else
               Assert
                 (Name /= "edit.word.delete-previous"
                  and then Name /= "edit.word.delete-next",
                  "Phase 404 registry must not expose duplicate Word Delete command names");
            end if;
         end;
      end loop;
      Assert (Previous_Count = 1 and then Next_Count = 1,
              "Phase 404 registry must contain exactly the canonical Word Delete descriptor pair");

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Filtered_Commands (Candidates);
      for C of Candidates loop
         if C.Id = Editor.Commands.Command_Word_Delete_Previous then
            Palette_Prev := Palette_Prev + 1;
            Assert (To_String (C.Name) = "Delete Previous Word",
                    "Phase 404 palette previous Word Delete label mismatch");
         elsif C.Id = Editor.Commands.Command_Word_Delete_Next then
            Palette_Next := Palette_Next + 1;
            Assert (To_String (C.Name) = "Delete Next Word",
                    "Phase 404 palette next Word Delete label mismatch");
         end if;
      end loop;
      Assert (Palette_Prev = 1 and then Palette_Next = 1,
              "Phase 404 Command Palette must expose exactly the canonical Word Delete pair");

      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Config.Build_From_Runtime (Config);
      for I in 1 .. Editor.Keybinding_Config.Binding_Count (Config) loop
         declare
            Command : constant Editor.Commands.Command_Id :=
              Editor.Keybinding_Config.Command_At (Config, I);
            Name    : constant String := Editor.Commands.Stable_Command_Name (Command);
         begin
            if Command = Editor.Commands.Command_Word_Delete_Previous then
               Assert (Name = "edit.word.delete-previous",
                       "Phase 404 default previous Word Delete keybinding must target canonical name");
            elsif Command = Editor.Commands.Command_Word_Delete_Next then
               Assert (Name = "edit.word.delete-next",
                       "Phase 404 default next Word Delete keybinding must target canonical name");
            end if;
         end;
      end loop;

      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put_Line (File, "editor-keybindings-version=1");
      Ada.Text_IO.Put_Line (File, "[bindings]");
      Ada.Text_IO.Put_Line (File, "edit.word.delete-previous=Ctrl+Alt+Backspace");
      Ada.Text_IO.Put_Line (File, "edit.word.delete-next=Ctrl+Alt+Delete");
      Ada.Text_IO.Close (File);

      Editor.Keybinding_Config.Load_From_File (Path, Config, Status);
      Assert (Status = Editor.Keybinding_Config.Keybinding_Config_Ok,
              "Phase 404 canonical Word Delete keybinding names must load cleanly");
      Chord := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Word_Delete_Previous, Found);
      Assert
        (Found and then Editor.Keybindings.Format_Chord (Chord) = "Ctrl+Alt+Backspace",
         "Phase 404 canonical previous Word Delete keybinding must remain loadable");
      Chord := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Word_Delete_Next, Found);
      Assert
        (Found and then Editor.Keybindings.Format_Chord (Chord) = "Ctrl+Alt+Delete",
         "Phase 404 canonical next Word Delete keybinding must remain loadable");

      Ada.Directories.Delete_File (Path);
      Editor.Keybindings.Reset_To_Defaults;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         if Ada.Directories.Exists (Path) then
            Ada.Directories.Delete_File (Path);
         end if;
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Phase404_Word_Delete_Canonical_Surface_Cleanup;


   procedure Test_Phase404_Word_Delete_Canonical_Routes_And_State_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      After        : Editor.State.State_Type;
      Chord        : constant Editor.Keybindings.Key_Chord :=
        (Key       => Editor.Keybindings.Key_Backspace,
         Modifiers => (Ctrl => True, Shift => True, Alt => True, Meta => False));
      Before_Clip  : Unbounded_String;
      Before_Back  : Natural := 0;
      Before_Fwd   : Natural := 0;
      Snap         : Editor.Render_Model.Render_Snapshot;
      Workspace    : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary      : Unbounded_String;
      Resolved_Id  : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.State.Set_Dirty (S, False);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIPBOARD"));
      Before_Clip := Editor.Clipboard.Get_Text;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Alpha ",
                          "Phase 404 canonical previous Word Delete id must use the only previous-word delete implementation path");
      Assert (Message_Text (S) = "Deleted previous word",
              "Phase 404 canonical previous Word Delete id must emit canonical Word Delete message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1
              and then Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 404 canonical previous Word Delete id must use canonical undo capture");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 404 canonical previous Word Delete id must use canonical dirty policy");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 404 Word Delete must not mutate Clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 404 Word Delete must not record Navigation History");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 404 render snapshot must derive from canonical post-delete buffer text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "Phase 404 undo for canonical Word Delete must restore captured Before_Text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha ",
                          "Phase 404 redo for canonical Word Delete must restore captured After_Text without re-running word logic");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, Cursor_Index (0));
      Editor.State.Set_Dirty (S, False);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, " Beta",
                          "Phase 404 canonical next Word Delete id must use the only next-word delete implementation path");
      Assert (Message_Text (S) = "Deleted next word",
              "Phase 404 canonical next Word Delete id must emit canonical Word Delete message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1
              and then Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 404 canonical next Word Delete id must use canonical undo capture");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 404 canonical next Word Delete id must not mutate Clipboard text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.State.Set_Dirty (S, False);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);

      Editor.Keybindings.Clear;
      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Word_Delete_Previous);
      Assert
        (Editor.Keybindings.Status (Editor.Keybindings.Validate) =
         Editor.Keybindings.Valid_Keybindings,
         "Phase 404 canonical Word Delete id must remain a valid keybinding target");
      Assert
        (Editor.Keybindings.Resolve (Chord, Resolved_Id) = Editor.Keybindings.Bound_Command
         and then Resolved_Id = Editor.Commands.Command_Word_Delete_Previous,
         "Phase 404 runtime keybinding resolution must expose only canonical Word Delete ids");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (After, " ",
         "Phase 404 Input_Bridge must dispatch canonical Word Delete keybindings through Executor");
      Assert (Message_Text (After) = "Deleted previous word",
              "Phase 404 canonical keybinding must emit one Word Delete message");
      Editor.Keybindings.Reset_To_Defaults;

      Workspace := Editor.State.Build_Workspace_Snapshot (After);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "word delete") = 0
         and then Index (Summary, "last deleted") = 0
         and then Index (Summary, "last word") = 0
         and then Index (Summary, "word-boundary") = 0
         and then Index (Summary, "semantic word") = 0
         and then Index (Summary, "kill-ring") = 0,
         "Phase 404 workspace persistence must exclude canonical and removed Word Delete state");
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Phase404_Word_Delete_Canonical_Routes_And_State_Boundaries;


   procedure Test_Phase404_Word_Delete_Behavior_Preservation_Smoke
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Clip : Unbounded_String;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
      Avail       : Editor.Commands.Command_Availability;
      Snap        : Editor.Render_Model.Render_Snapshot;
   begin
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha   |Beta", "|Beta", "Alpha   ",
         "Phase 404 preservation previous whitespace plus prior word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha...|", "Alpha|", "...",
         "Phase 404 preservation previous punctuation run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha |  Beta", "Alpha |", "  Beta",
         "Phase 404 preservation next whitespace plus following word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|Alpha_Beta123", "|", "Alpha_Beta123",
         "Phase 404 preservation next underscore and digit word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha" & ASCII.LF & "  |Beta", "|Beta",
         "Alpha" & ASCII.LF & "  ",
         "Phase 404 preservation previous cross-line whitespace policy");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha|" & ASCII.LF & "  Beta", "Alpha|",
         ASCII.LF & "  Beta",
         "Phase 404 preservation next cross-line whitespace policy");
      Assert_Word_Delete_No_Op
        (Word_Delete_Test_Previous, "|Alpha",
         "Phase 404 preservation previous start no-op");
      Assert_Word_Delete_No_Op
        (Word_Delete_Test_Next, "Alpha|",
         "Phase 404 preservation next end no-op");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Set_Primary_Selection (S, 0, 6);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Before_Clip := Editor.Clipboard.Get_Text;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Beta");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 404 canonical next Word Delete availability must remain available");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 404 pre-delete render snapshot must be side-effect-free");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha  Gamma",
                          "Phase 404 canonical delete-next smoke text mismatch");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 404 successful Word Delete must collapse stale active selection");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Phase 404 text-changing Word Delete must use canonical Find invalidation");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 404 canonical Word Delete must preserve Clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 404 canonical Word Delete must preserve Navigation History stacks");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 404 post-delete render snapshot must come from canonical buffer text");
   end Test_Phase404_Word_Delete_Behavior_Preservation_Smoke;


   type Character_Delete_Test_Direction is
     (Character_Delete_Test_Previous,
      Character_Delete_Test_Next);

   procedure Assert_Character_Delete_Transform
     (Direction : Character_Delete_Test_Direction;
      Before    : String;
      Expected  : String;
      Why       : String)
   is
      S             : Editor.State.State_Type;
      Before_Clip   : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Text   : constant String := Strip_Caret_Marker (Before);
      Before_Caret  : constant Cursor_Index := Caret_From_Marked (Before);
      Expected_Text  : constant String := Strip_Caret_Marker (Expected);
      Expected_Caret : constant Cursor_Index := Caret_From_Marked (Expected);
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, Before_Caret);

      if Direction = Character_Delete_Test_Previous then
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Char_Delete_Previous);
         Assert (Message_Text (S) = "Deleted previous character",
                 Why & ": delete-previous message mismatch");
      else
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Char_Delete_Next);
         Assert (Message_Text (S) = "Deleted next character",
                 Why & ": delete-next message mismatch");
      end if;

      Assert_Buffer_Text (S, Expected_Text, Why);
      Assert (S.Carets (S.Carets.First_Index).Pos = Expected_Caret,
              Why & ": caret mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              Why & ": character delete must create one undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              Why & ": character delete must leave redo empty");
      Assert (Editor.State.Is_Dirty (S),
              Why & ": character delete must dirty a clean buffer");
      Assert (not Editor.Selection.Has_Selection (S),
              Why & ": selection must be valid or empty after mutation");
      Assert (Editor.Clipboard.Has_Text
              and then Editor.Clipboard.Get_Text = Before_Clip,
              Why & ": character delete must not mutate clipboard");
      Assert_Navigation_Counts (S, 0, 0,
                                Why & ": character delete must not record navigation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, Before_Text,
                          Why & ": undo must restore exact pre-delete text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, Expected_Text,
                          Why & ": redo must restore exact post-delete text");
   end Assert_Character_Delete_Transform;

   procedure Assert_Character_Delete_No_Op
     (Direction : Character_Delete_Test_Direction;
      Before    : String;
      Why       : String)
   is
      S           : Editor.State.State_Type;
      Before_Text : constant String := Strip_Caret_Marker (Before);
      Before_Clip : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Redo_Count  : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Seed");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);

      Editor.State.Load_Text (S, Before_Text);
      Set_Caret (S, Caret_From_Marked (Before));

      if Direction = Character_Delete_Test_Previous then
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Char_Delete_Previous);
      else
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Char_Delete_Next);
      end if;

      Assert_Buffer_Text (S, Before_Text, Why);
      Assert (Message_Text (S) = "Nothing to delete",
              Why & ": no-op message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              Why & ": no-op character delete must not create undo");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              Why & ": no-op character delete must preserve redo stack");
      Assert (Editor.Clipboard.Has_Text
              and then Editor.Clipboard.Get_Text = Before_Clip,
              Why & ": no-op character delete must not mutate clipboard");
   end Assert_Character_Delete_No_Op;

   procedure Test_Phase405_Character_Delete_Command_Descriptors_And_Routes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      S     : Editor.State.State_Type;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Char_Delete_Previous) =
         "edit.char.delete-previous",
         "Phase 405 previous-character delete stable name mismatch");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Char_Delete_Next) =
         "edit.char.delete-next",
         "Phase 405 next-character delete stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Char_Delete_Previous).Category =
         Editor.Commands.Edit_Category,
         "Phase 405 previous-character delete must be an Edit command");
      Assert
        (Editor.Commands.Visible_In_Command_Palette
           (Editor.Commands.Command_Char_Delete_Next),
         "Phase 405 next-character delete must be palette visible");
      Assert
        (Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Char_Delete_Previous)
         and then Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Char_Delete_Next),
         "Phase 405 Character Delete commands must be bindable");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("edit.char.delete-previous", Found) =
         Editor.Commands.Command_Char_Delete_Previous and then Found,
         "Phase 405 previous-character stable name must resolve");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("edit.char.delete-next", Found) =
         Editor.Commands.Command_Char_Delete_Next and then Found,
         "Phase 405 next-character stable name must resolve");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AB");
      Set_Caret (S, 1);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text (S, "A", "Phase 405 next-character command must route through Executor");
      Assert (Message_Text (S) = "Deleted next character",
              "Phase 405 next-character routed message mismatch");
   end Test_Phase405_Character_Delete_Command_Descriptors_And_Routes;

   procedure Test_Phase405_Delete_Previous_Character_Boundaries_Selection_And_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha|", "Alph|",
         "Phase 405 delete previous at line end");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "A|lpha", "|lpha",
         "Phase 405 delete previous in middle of line");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha | Beta", "Alpha| Beta",
         "Phase 405 delete previous whitespace");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha.|", "Alpha|",
         "Phase 405 delete previous punctuation");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & "|Beta", "Alpha|Beta",
         "Phase 405 delete previous line boundary");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Previous, "|Alpha",
         "Phase 405 delete previous at buffer start no-op");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "ABCD");
      Set_Primary_Selection (S, 0, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text (S, "ABC", "Phase 405 character delete must operate at caret only");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 405 successful character delete must collapse selection");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 405 character delete must not consume/copy selection");
   end Test_Phase405_Delete_Previous_Character_Boundaries_Selection_And_Undo;

   procedure Test_Phase405_Delete_Next_Character_Boundaries_No_Ops_And_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
   begin
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "|Alpha", "|lpha",
         "Phase 405 delete next at line start");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Al|pha", "Al|ha",
         "Phase 405 delete next in middle of line");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha | Beta", "Alpha |Beta",
         "Phase 405 delete next whitespace");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "|.Alpha", "|Alpha",
         "Phase 405 delete next punctuation");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & "Beta", "Alpha|Beta",
         "Phase 405 delete next line boundary");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Next, "Alpha|",
         "Phase 405 delete next at buffer end no-op");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "ABCD");
      Set_Caret (S, 1);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 1, Has_File_Path => False,
          File_Path => Null_Unbounded_String,
          Display_Path => Null_Unbounded_String,
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 1, Has_File_Path => False,
          File_Path => Null_Unbounded_String,
          Display_Path => Null_Unbounded_String,
          Line => 1, Column => 1, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));
      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 1, Has_File_Path => False,
          File_Path => Null_Unbounded_String,
          Display_Path => Null_Unbounded_String,
          Line => 1, Column => 2, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Forward));
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text (S, "ACD", "Phase 405 character delete after navigation must edit active text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 405 character delete must preserve Navigation History stacks");
   end Test_Phase405_Delete_Next_Character_Boundaries_No_Ops_And_State;


   procedure Test_Phase405_Character_Delete_Completeness_Routes_State_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      No_Buffer     : Editor.State.State_Type;
      After         : Editor.State.State_Type;
      Avail         : Editor.Commands.Command_Availability;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Before_Text   : Unbounded_String;
      Before_Caret  : Cursor_Index := 0;
      Before_Dirty  : Boolean := False;
      Before_Undo   : Natural := 0;
      Before_Redo   : Natural := 0;
      Before_Clip   : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Chord         : constant Editor.Keybindings.Key_Chord :=
        Editor.Keybindings.Key_Chord'
          (Key       => Editor.Keybindings.Key_H,
           Modifiers =>
             (Ctrl  => True,
              Shift => True,
              Alt   => True,
              Meta  => False));
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);

      Editor.State.Init (No_Buffer);
      Avail := Editor.Executor.Command_Availability
        (No_Buffer, Editor.Commands.Command_Char_Delete_Previous);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No active buffer.",
              "Phase 405 previous-character no-active-buffer availability must be deterministic");
      Editor.Executor.Execute_Command
        (No_Buffer, Editor.Commands.Command_Char_Delete_Previous);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "Phase 405 previous-character no-active-buffer execution message mismatch");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AB");
      S.Carets.Clear;
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Char_Delete_Next);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No caret location",
              "Phase 405 next-character no-caret availability must be deterministic");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert (Message_Text (S) = "No caret location",
              "Phase 405 next-character no-caret execution message mismatch");
      Assert_Buffer_Text (S, "AB",
                          "Phase 405 no-caret character delete must not mutate text");

      Editor.State.Load_Text (S, "ABCD");
      Set_Caret (S, 2);
      Editor.State.Set_Dirty (S, False);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 405 character delete must be available for active buffer and caret");
      Assert (To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer)) = Before_Text
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret
              and then Editor.State.Is_Dirty (S) = Before_Dirty
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo
              and then Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 405 character delete availability must be side-effect-free");

      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Char_Delete_Previous);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (After, "ACD",
         "Phase 405 Input_Bridge must dispatch previous-character delete through Executor");
      Assert (Message_Text (After) = "Deleted previous character",
              "Phase 405 Input_Bridge previous-character route message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo + 1,
              "Phase 405 Input_Bridge previous-character route must create one undo entry");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 405 routed character delete must not mutate Clipboard");

      Editor.Render_Model.Build_Render_Snapshot (After, Snap);
      Assert (Snap.Length = Text_Buffer.Length (After.Buffer),
              "Phase 405 render snapshot must derive from post-character-delete buffer text");

      Workspace := Editor.State.Build_Workspace_Snapshot (After);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "character delete") = 0
         and then Index (Summary, "deleted character") = 0
         and then Index (Summary, "last character") = 0
         and then Index (Summary, "char-delete") = 0
         and then Index (Summary, "character-boundary") = 0
         and then Index (Summary, "kill-ring") = 0,
         "Phase 405 workspace persistence must exclude Character Delete transient state");

      Editor.Keybindings.Reset_To_Defaults;
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Phase405_Character_Delete_Completeness_Routes_State_And_Persistence;


   procedure Test_Phase406_Character_Delete_Previous_Reliability_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Redo_Count : Natural := 0;
   begin
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha|", "Alph|",
         "Phase 406 delete-previous ordinary end character");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "A|lpha", "|lpha",
         "Phase 406 delete-previous ordinary middle character");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha | Beta", "Alpha| Beta",
         "Phase 406 delete-previous treats space as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha" & ASCII.HT & "|Beta", "Alpha|Beta",
         "Phase 406 delete-previous treats tab as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha.|", "Alpha|",
         "Phase 406 delete-previous treats punctuation as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & "|Beta", "Alpha|Beta",
         "Phase 406 delete-previous removes exactly the previous line boundary");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, ASCII.LF & "|Beta", "|Beta",
         "Phase 406 delete-previous removes leading line boundary only");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha|" & ASCII.LF & "Beta", "Alph|" & ASCII.LF & "Beta",
         "Phase 406 delete-previous at line end deletes preceding character not next boundary");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & ASCII.LF & "|Beta", "Alpha" & ASCII.LF & "|Beta",
         "Phase 406 delete-previous before blank line removes one boundary only");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & "  |Beta", "Alpha" & ASCII.LF & " |Beta",
         "Phase 406 delete-previous before indented text deletes one space only");

      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Previous, "|Alpha",
         "Phase 406 delete-previous at buffer start no-ops");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Previous, "|",
         "Phase 406 delete-previous in empty buffer no-ops");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Seed");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 406 successful delete-previous after undo must clear redo stack");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Seed");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "Phase 406 no-op delete-previous after undo must preserve redo stack");
   end Test_Phase406_Character_Delete_Previous_Reliability_Matrix;

   procedure Test_Phase406_Character_Delete_Next_Reliability_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Redo_Count : Natural := 0;
   begin
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "|Alpha", "|lpha",
         "Phase 406 delete-next ordinary first character");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Al|pha", "Al|ha",
         "Phase 406 delete-next ordinary middle character");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha | Beta", "Alpha |Beta",
         "Phase 406 delete-next treats space as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.HT & "Beta", "Alpha|Beta",
         "Phase 406 delete-next treats tab as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "|.Alpha", "|Alpha",
         "Phase 406 delete-next treats punctuation as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & "Beta", "Alpha|Beta",
         "Phase 406 delete-next removes exactly the following line boundary");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha" & ASCII.LF & "|Beta", "Alpha" & ASCII.LF & "|eta",
         "Phase 406 delete-next at line start deletes following text character");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF, "Alpha|",
         "Phase 406 delete-next removes trailing newline boundary only");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & ASCII.LF & "Beta", "Alpha|" & ASCII.LF & "Beta",
         "Phase 406 delete-next before blank line removes one boundary only");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & "  Beta", "Alpha|  Beta",
         "Phase 406 delete-next before whitespace-only prefix removes boundary only");

      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Next, "Alpha|",
         "Phase 406 delete-next at buffer end no-ops");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Next, "|",
         "Phase 406 delete-next in empty buffer no-ops");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Seed");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 406 successful delete-next after undo must clear redo stack");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Seed");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "Phase 406 no-op delete-next after undo must preserve redo stack");
   end Test_Phase406_Character_Delete_Next_Reliability_Matrix;

   procedure Test_Phase406_Character_Delete_State_Integration_And_Read_Only_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Avail         : Editor.Commands.Command_Availability;
      Before_Text   : Unbounded_String;
      Before_Caret  : Cursor_Index := 0;
      Before_Dirty  : Boolean := False;
      Before_Undo   : Natural := 0;
      Before_Redo   : Natural := 0;
      Before_Back   : Natural := 0;
      Before_Fwd    : Natural := 0;
      Before_Clip   : constant Unbounded_String := To_Unbounded_String ("CLIP");
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Selection (S, 0, 6);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Beta");
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 1, Has_File_Path => False,
          File_Path => Null_Unbounded_String,
          Display_Path => Null_Unbounded_String,
          Line => 1, Column => 1, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));
      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 1, Has_File_Path => False,
          File_Path => Null_Unbounded_String,
          Display_Path => Null_Unbounded_String,
          Line => 1, Column => 2, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Forward));
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "Alpha eta Gamma",
         "Phase 406 delete-next must operate at caret, not consume selection");
      Assert (S.Carets (S.Carets.First_Index).Pos = 6,
              "Phase 406 delete-next caret must remain at deletion start");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 406 successful Character Delete must clear selection");
      Assert (Editor.Clipboard.Has_Text and then Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 406 Character Delete must preserve Clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 406 Character Delete must not record or clear Navigation History");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Phase 406 text-changing Character Delete must use canonical Find invalidation");
      Assert (To_String (S.Active_Find_Query) = "Beta",
              "Phase 406 Character Delete must not mutate Find query text");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 406 render snapshot must reflect post-delete active-buffer text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 406 text-changing Character Delete must create exactly one undo entry");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "ABCD");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 2);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 406 Character Delete availability must remain available with active buffer and caret");
      Assert (To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer)) = Before_Text
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret
              and then Editor.State.Is_Dirty (S) = Before_Dirty
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo
              and then Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 406 Character Delete availability must be side-effect-free");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer)) = Before_Text
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 406 render snapshot must not repair or perform Character Delete");
   end Test_Phase406_Character_Delete_State_Integration_And_Read_Only_Boundaries;

   procedure Test_Phase406_Character_Delete_Mixed_Command_Coexistence_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S         : Editor.State.State_Type;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary   : Unbounded_String;
   begin
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha Beta|", "Alpha Bet|",
         "Phase 406 delete-previous remains one text unit after word-delete-capable text");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha |Beta", "Alpha |eta",
         "Phase 406 delete-next remains one text unit before word-delete-capable text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "Phase 406 split then delete-previous must remove canonical boundary without invoking Line Join");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 2,
              "Phase 406 mixed split/delete workflow must preserve undo ordering");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "Phase 406 undo after split/delete must restore split text exactly");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "Phase 406 redo after split/delete must restore post-delete text exactly");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "Phase 406 join then delete-next must use resulting active-buffer text only");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "   Alpha");
      Set_Caret (S, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "Alpha",
         "Phase 406 indentation then delete-next must not share corruptible transient state");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "- Alpha",
         "Phase 406 comment then delete-next treats comment marker as plain text");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "character delete") = 0
         and then Index (Summary, "deleted character") = 0
         and then Index (Summary, "last character") = 0
         and then Index (Summary, "char-delete") = 0
         and then Index (Summary, "character-boundary") = 0
         and then Index (Summary, "grapheme") = 0
         and then Index (Summary, "kill-ring") = 0,
         "Phase 406 workspace persistence must exclude Character Delete reliability state");
   end Test_Phase406_Character_Delete_Mixed_Command_Coexistence_And_Persistence;

   procedure Assert_Character_Delete_Transform_Exact
     (Direction    : Character_Delete_Test_Direction;
      Before       : String;
      Expected     : String;
      Removed_Text : String;
      Why          : String)
   is
      S              : Editor.State.State_Type;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Text    : constant String := Strip_Caret_Marker (Before);
      Before_Caret   : constant Cursor_Index := Caret_From_Marked (Before);
      Expected_Text   : constant String := Strip_Caret_Marker (Expected);
      Expected_Caret  : constant Cursor_Index := Caret_From_Marked (Expected);
      Delete_Start    : Natural := 0;
      Delete_End      : Natural := 0;
   begin
      if Direction = Character_Delete_Test_Previous then
         Delete_Start := Natural (Expected_Caret);
         Delete_End := Natural (Before_Caret);
      else
         Delete_Start := Natural (Before_Caret);
         Delete_End := Natural (Before_Caret) + Removed_Text'Length;
      end if;

      Assert
        (Slice_Zero_Based (Before_Text, Delete_Start, Delete_End) = Removed_Text,
         Why & ": removed text mismatch");
      Assert
        (Slice_Zero_Based (Before_Text, 0, Delete_Start)
         & Slice_Zero_Based (Before_Text, Delete_End, Before_Text'Length)
         = Expected_Text,
         Why & ": computed adjacent range does not reconstruct expected text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, Before_Caret);

      if Direction = Character_Delete_Test_Previous then
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Char_Delete_Previous);
         Assert (Message_Text (S) = "Deleted previous character",
                 Why & ": delete-previous message mismatch");
      else
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Char_Delete_Next);
         Assert (Message_Text (S) = "Deleted next character",
                 Why & ": delete-next message mismatch");
      end if;

      Assert_Buffer_Text (S, Expected_Text, Why);
      Assert (S.Carets (S.Carets.First_Index).Pos = Expected_Caret,
              Why & ": caret mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              Why & ": text-changing Character Delete must create one undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              Why & ": text-changing Character Delete must clear redo");
      Assert (Editor.State.Is_Dirty (S),
              Why & ": text-changing Character Delete must dirty clean buffer");
      Assert (not Editor.Selection.Has_Selection (S),
              Why & ": selection must be empty or valid after delete");
      Assert (Editor.Clipboard.Has_Text and then Editor.Clipboard.Get_Text = Before_Clip,
              Why & ": Character Delete must not mutate Clipboard");
      Assert_Navigation_Counts (S, 0, 0,
                                Why & ": Character Delete must not record navigation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, Before_Text,
                          Why & ": undo must restore exact pre-delete text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, Expected_Text,
                          Why & ": redo must restore exact post-delete text");
   end Assert_Character_Delete_Transform_Exact;

   procedure Test_Phase407_Character_Delete_Boundary_Transform_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha|", "Alph|", "a",
         "Phase 407 previous ordinary end transform");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "A|lpha", "|lpha", "A",
         "Phase 407 previous ordinary middle transform");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Previous, "|Alpha",
         "Phase 407 previous buffer-start no-op");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha | Beta", "Alpha| Beta", " ",
         "Phase 407 previous deletes exactly one space");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha" & ASCII.HT & "|Beta", "Alpha|Beta", "" & ASCII.HT,
         "Phase 407 previous deletes exactly one tab");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha.|", "Alpha|", ".",
         "Phase 407 previous deletes exactly one punctuation unit");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & "|Beta", "Alpha|Beta", "" & ASCII.LF,
         "Phase 407 previous deletes exactly previous line boundary");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha|" & ASCII.LF & "Beta", "Alph|" & ASCII.LF & "Beta", "a",
         "Phase 407 previous at line end deletes preceding character");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, ASCII.LF & "|Beta", "|Beta", "" & ASCII.LF,
         "Phase 407 previous removes leading boundary only");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & ASCII.LF & "|Beta", "Alpha" & ASCII.LF & "|Beta", "" & ASCII.LF,
         "Phase 407 previous before blank line removes one boundary");

      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "|Alpha", "|lpha", "A",
         "Phase 407 next ordinary first transform");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Al|pha", "Al|ha", "p",
         "Phase 407 next ordinary middle transform");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Next, "Alpha|",
         "Phase 407 next buffer-end no-op");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha | Beta", "Alpha |Beta", " ",
         "Phase 407 next deletes exactly one space");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha|" & ASCII.HT & "Beta", "Alpha|Beta", "" & ASCII.HT,
         "Phase 407 next deletes exactly one tab");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "|.Alpha", "|Alpha", ".",
         "Phase 407 next deletes exactly one punctuation unit");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & "Beta", "Alpha|Beta", "" & ASCII.LF,
         "Phase 407 next deletes exactly following line boundary");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha" & ASCII.LF & "|Beta", "Alpha" & ASCII.LF & "|eta", "B",
         "Phase 407 next at line start deletes following character");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF, "Alpha|", "" & ASCII.LF,
         "Phase 407 next removes trailing newline boundary only");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & ASCII.LF & "Beta", "Alpha|" & ASCII.LF & "Beta", "" & ASCII.LF,
         "Phase 407 next before blank line removes one boundary");
   end Test_Phase407_Character_Delete_Boundary_Transform_Workflows;

   procedure Test_Phase407_Character_Delete_State_Find_Clipboard_Navigation_Render
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Snap           : Editor.Render_Model.Render_Snapshot;
      Avail          : Editor.Commands.Command_Availability;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Before_Text    : Unbounded_String;
      Before_Caret   : Cursor_Index := 0;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Before_Dirty   : Boolean := False;
      Redo_Count     : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Selection (S, 0, 11);
      S.Active_Replace_Prompt := True;
      S.Active_Replace_Text := To_Unbounded_String ("BETA");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Beta");
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 1, Has_File_Path => False,
          File_Path => Null_Unbounded_String,
          Display_Path => Null_Unbounded_String,
          Line => 1, Column => 1, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));
      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 1, Has_File_Path => False,
          File_Path => Null_Unbounded_String,
          Display_Path => Null_Unbounded_String,
          Line => 1, Column => 2, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Forward));
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Set_Caret (S, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text
        (S, "Alpha Bea Gamma",
         "Phase 407 previous delete must remove exact adjacent character after selection/find setup");
      Assert (S.Carets (S.Carets.First_Index).Pos = 9,
              "Phase 407 previous delete caret must move to deleted range start");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 407 successful Character Delete must clear active selection");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Phase 407 text-changing Character Delete must invalidate Find matches");
      Assert (To_String (S.Active_Find_Query) = "Beta",
              "Phase 407 Character Delete must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("BETA")
              and then S.Active_Replace_Prompt,
              "Phase 407 Character Delete must not mutate Replace text or visibility");
      Assert (Editor.Clipboard.Has_Text and then Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 407 Character Delete must not mutate Clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 407 Character Delete must preserve Navigation History stacks");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1
              and then Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 407 text-changing Character Delete must create exactly one undo entry and clear redo");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 407 render snapshot must derive from post-delete buffer text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta Gamma",
                          "Phase 407 undo restores pre-delete text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha Bea Gamma",
                          "Phase 407 redo restores post-delete text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Seed");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "Phase 407 no-op previous delete after undo must preserve redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "See",
                          "Phase 407 redo after no-op previous delete must remain available");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "ABCD");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 2);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Dirty := Editor.State.Is_Dirty (S);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Char_Delete_Next);
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 407 Character Delete availability must be available with active buffer and caret");
      declare
         Candidates : Editor.Commands.Command_Descriptor_Vectors.Vector;
      begin
         Editor.Command_Palette.Reset;
         Editor.Command_Palette.Filtered_Commands (Candidates);
         Assert (Candidates.Length > 0,
                 "Phase 407 Command Palette projection must produce candidates");
      end;
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer)) = Before_Text
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo
              and then Editor.State.Is_Dirty (S) = Before_Dirty,
              "Phase 407 availability/palette/render paths must be side-effect-free");
   end Test_Phase407_Character_Delete_State_Find_Clipboard_Navigation_Render;

   procedure Test_Phase407_Character_Delete_Mixed_Command_Coexistence_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Word_Delete_Previous);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text
        (S, "Alpha",
         "Phase 407 word-delete then char-delete-previous must use resulting canonical text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Word_Delete_Next);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "Beta",
         "Phase 407 word-delete-next then char-delete-next must use resulting canonical text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "AlphaBeta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "Phase 407 split then delete-previous must delete boundary without invoking Line Join");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "Phase 407 undo in split/delete workflow restores exact split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "Phase 407 redo in split/delete workflow restores exact post-delete text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "Phase 407 join then delete-next must use resulting canonical text only");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "eta" & ASCII.LF & "Beta",
         "Phase 407 duplicate-line then delete-next remains ordinary adjacent deletion");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "   Alpha");
      Set_Caret (S, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "Alpha",
         "Phase 407 indentation then delete-next must not share transient state");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "- Alpha",
         "Phase 407 line-comment then delete-next treats comment marker as plain text");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 407 mixed workflows must not let Character Delete mutate Clipboard");
   end Test_Phase407_Character_Delete_Mixed_Command_Coexistence_Workflows;

   procedure Test_Phase407_Character_Delete_Active_Buffer_Routes_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      No_Buffer      : Editor.State.State_Type;
      After          : Editor.State.State_Type;
      A              : Editor.Buffers.Buffer_Id;
      B              : Editor.Buffers.Buffer_Id;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Found          : Boolean := False;
      Chord          : constant Editor.Keybindings.Key_Chord :=
        Editor.Keybindings.Key_Chord'
          (Key       => Editor.Keybindings.Key_Delete,
           Modifiers =>
             (Ctrl  => True,
              Shift => True,
              Alt   => True,
              Meta  => False));
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Buffers.Ensure_Global_Registry (S);
      A := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "Gamma");
      Set_Caret (S, 0);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text (S, "Alph",
                          "Phase 407 active-buffer A Character Delete text");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Buffer_Text (S, "Gamma",
                          "Phase 407 active-buffer B must be isolated from A Character Delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text (S, "amma",
                          "Phase 407 active-buffer B independent Character Delete text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Gamma",
                          "Phase 407 undo in B affects only B");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Buffer_Text (S, "Alph",
                          "Phase 407 returning to A preserves A Character Delete result");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha",
                          "Phase 407 undo in A affects only A");

      Editor.State.Init (No_Buffer);
      Editor.Executor.Execute_Command
        (No_Buffer, Editor.Commands.Command_Char_Delete_Previous);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "Phase 407 no-active-buffer previous delete message mismatch");
      Editor.Executor.Execute_Command
        (No_Buffer, Editor.Commands.Command_Char_Delete_Next);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "Phase 407 no-active-buffer next delete message mismatch");

      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Char_Delete_Next);
      Set_Caret (S, 0);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (After, "lpha",
         "Phase 407 Input_Bridge keybinding must route char-delete-next through Executor");
      Assert (Message_Text (After) = "Deleted next character",
              "Phase 407 routed char-delete-next message mismatch");
      Editor.Keybindings.Reset_To_Defaults;

      declare
         Dummy : Editor.Commands.Command_Id;
      begin
         Dummy := Editor.Commands.Command_Id_From_Stable_Name
           ("edit.char.delete-current", Found);
         Assert (Dummy = Editor.Commands.No_Command and then not Found,
                 "Phase 407 non-goal delete-current command must not resolve");
         Dummy := Editor.Commands.Command_Id_From_Stable_Name
           ("edit.char.kill", Found);
         Assert (Dummy = Editor.Commands.No_Command and then not Found,
                 "Phase 407 non-goal char-kill command must not resolve");
         Dummy := Editor.Commands.Command_Id_From_Stable_Name
           ("selection.delete", Found);
         Assert (Found and then Dummy = Editor.Commands.Command_Selection_Delete,
                 "Phase 541 selection-delete command must resolve through canonical selection namespace");
      end;

      Workspace := Editor.State.Build_Workspace_Snapshot (After);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "character delete") = 0
         and then Index (Summary, "deleted character") = 0
         and then Index (Summary, "last character") = 0
         and then Index (Summary, "last deleted") = 0
         and then Index (Summary, "char-delete") = 0
         and then Index (Summary, "character-boundary") = 0
         and then Index (Summary, "grapheme") = 0
         and then Index (Summary, "text-shaping") = 0
         and then Index (Summary, "kill-ring") = 0,
         "Phase 407 workspace persistence must exclude Character Delete workflow state");
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Phase407_Character_Delete_Active_Buffer_Routes_And_Persistence;


procedure Test_Phase408_Character_Delete_Canonical_Routes_State_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      After        : Editor.State.State_Type;
      Prev_Chord   : constant Editor.Keybindings.Key_Chord :=
        (Key       => Editor.Keybindings.Key_Backspace,
         Modifiers => (Ctrl => False, Shift => False, Alt => False, Meta => False));
      Next_Chord   : constant Editor.Keybindings.Key_Chord :=
        (Key       => Editor.Keybindings.Key_Delete,
         Modifiers => (Ctrl => False, Shift => False, Alt => False, Meta => False));
      Resolved_Id  : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Bind_Status  : Editor.Keybindings.Binding_Result;
      Before_Clip  : constant Unbounded_String := To_Unbounded_String ("CLIPBOARD");
      Workspace    : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary      : Unbounded_String;
      Snap         : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);

      Bind_Status := Editor.Keybindings.Resolve (Prev_Chord, Resolved_Id);
      Assert
        (Bind_Status = Editor.Keybindings.Bound_Command
         and then Resolved_Id = Editor.Commands.Command_Char_Delete_Previous,
         "Phase 408 default Backspace binding must route to canonical previous-character delete");
      Bind_Status := Editor.Keybindings.Resolve (Next_Chord, Resolved_Id);
      Assert
        (Bind_Status = Editor.Keybindings.Bound_Command
         and then Resolved_Id = Editor.Commands.Command_Char_Delete_Next,
         "Phase 408 default Delete binding must route to canonical next-character delete");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "ABC");
      Editor.State.Set_Dirty (S, False);

      Set_Primary_Selection (S, 0, 2);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Prev_Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (After, "AC",
         "Phase 408 routed default Backspace must use canonical adjacent previous-character delete");
      Assert
        (Message_Text (After) = "Deleted previous character",
         "Phase 408 routed default Backspace message mismatch");
      Assert
        (Natural (Editor.History.Undo_Stack.Length) = 1
         and then Natural (Editor.History.Redo_Stack.Length) = 0,
         "Phase 408 routed default Backspace must create exactly one canonical undo entry");
      Assert
        (Editor.State.Is_Dirty (After),
         "Phase 408 routed default Backspace must dirty through canonical policy");
      Assert
        (not Editor.Selection.Has_Selection (After),
         "Phase 408 routed default Backspace must collapse selection through canonical mutation policy");
      Assert
        (Editor.Clipboard.Get_Text = Before_Clip,
         "Phase 408 routed default Backspace must not mutate Clipboard");
      Assert_Navigation_Counts
        (After, 0, 0,
         "Phase 408 routed default Backspace must not record Navigation History");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "ABC");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Selection (S, 2, 0);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Next_Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (After, "BC",
         "Phase 408 routed default Delete must use canonical adjacent next-character delete");
      Assert
        (Message_Text (After) = "Deleted next character",
         "Phase 408 routed default Delete message mismatch");
      Assert
        (Natural (Editor.History.Undo_Stack.Length) = 1
         and then Natural (Editor.History.Redo_Stack.Length) = 0,
         "Phase 408 routed default Delete must create exactly one canonical undo entry");
      Assert
        (Editor.Clipboard.Get_Text = Before_Clip,
         "Phase 408 routed default Delete must not mutate Clipboard");

      Editor.Executor.Execute_Command (After, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (After, "ABC",
         "Phase 408 undo after canonical Character Delete must restore captured Before_Text");
      Editor.Executor.Execute_Command (After, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (After, "BC",
         "Phase 408 redo after canonical Character Delete must restore captured After_Text without rerunning range logic");

      Editor.Render_Model.Build_Render_Snapshot (After, Snap);
      Assert
        (Snap.Length = Text_Buffer.Length (After.Buffer),
         "Phase 408 render snapshot length must derive from canonical buffer text only");

      Workspace := Editor.State.Build_Workspace_Snapshot (After);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "character delete") = 0
         and then Index (Summary, "deleted character") = 0
         and then Index (Summary, "last character") = 0
         and then Index (Summary, "last deleted") = 0
         and then Index (Summary, "char-delete") = 0
         and then Index (Summary, "character-boundary") = 0
         and then Index (Summary, "grapheme") = 0
         and then Index (Summary, "text-shaping") = 0
         and then Index (Summary, "kill-ring") = 0,
         "Phase 408 workspace persistence must exclude canonical and removed Character Delete transient state");
      Editor.Keybindings.Reset_To_Defaults;
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Phase408_Character_Delete_Canonical_Routes_State_And_Persistence;





   procedure Test_Phase409_Selection_Delete_Command_Descriptors_And_Routes





     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      D     : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Selection_Delete);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      S     : Editor.State.State_Type;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Selection_Delete) = "selection.delete",
         "selection delete must have stable persisted command name");
      Assert
        (D.Category = Editor.Commands.Edit_Category,
         "selection delete must be an Edit command");
      Assert
        (D.Visibility = Editor.Commands.Palette_Command,
         "selection delete must be command-palette visible");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Selection_Delete),
         "selection delete must be bindable");
      Assert
        (Editor.Commands.Is_Text_Editing_Command
           (Editor.Commands.Command_Selection_Delete),
         "selection delete must be classified as a text editing command");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("selection.delete", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Selection_Delete,
         "selection delete stable name must resolve to the command id");
      Assert
        (Editor.Commands.Command_For_Id
           (Editor.Commands.Command_Selection_Delete).Kind =
         Editor.Commands.Delete_Selection_Range,
         "selection delete id must create the canonical edit command kind");

      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Primary_Selection (S, 0, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, " Beta", "selection delete executor route");
      Assert
        (Message_Text (S) = "Deleted selection",
         "selection delete must report one success message");
   end Test_Phase409_Selection_Delete_Command_Descriptors_And_Routes;

   procedure Test_Phase409_Selection_Delete_Range_Matrix_And_Backward_Selection

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      procedure Check
        (Before_Text : String;
         Anchor      : Cursor_Index;
         Pos         : Cursor_Index;
         Expected    : String;
         Why         : String)
      is
         S : Editor.State.State_Type;
      begin
         Editor.State.Load_Text (S, Before_Text);
         Set_Primary_Selection (S, Anchor, Pos);
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
         Assert_Buffer_Text (S, Expected, Why);
         Assert
           (not Editor.Selection.Has_Selection (S),
            Why & ": successful delete must clear/collapse selection");
         Assert
           (Natural (S.Carets (S.Carets.First_Index).Pos) =
            Natural (Cursor_Index'Min (Anchor, Pos)),
            Why & ": caret must move to deletion start");
         Assert
           (Natural (Editor.History.Undo_Stack.Length) = 1,
            Why & ": delete must create one undo entry");
      end Check;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Check ("Alpha Beta", 0, 5, " Beta", "delete selected prefix");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Check ("Alpha Beta", 6, 10, "Alpha ", "delete selected suffix");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Check ("Alpha Beta", 2, 8, "Alta", "delete selected middle");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Check
        ("Alpha" & ASCII.LF & "Beta", 5, 6,
         "AlphaBeta", "delete selected line boundary");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Check
        ("Alpha" & ASCII.LF & "Beta", 5, 10,
         "Alpha", "delete selected boundary and following line text");
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Check
        ("Alpha" & ASCII.LF & "Beta", 6, 0,
         "Beta", "backward selection normalizes to same range");
   end Test_Phase409_Selection_Delete_Range_Matrix_And_Backward_Selection;

   procedure Test_Phase409_Selection_Delete_Undo_Redo_Clipboard_Navigation_And_No_Op

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Before_Redo   : Natural := 0;
      Before_Back   : Natural := 0;
      Before_Fwd    : Natural := 0;
      Before_Clip   : constant Unbounded_String := To_Unbounded_String ("kept clipboard");
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma");
      Set_Primary_Selection (S, 6, 10);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & ASCII.LF & "Gamma",
         "selection delete must remove exact selected text");
      Assert
        (Editor.Clipboard.Get_Text = Before_Clip,
         "selection delete must not mutate clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "selection delete must not record navigation history");
      Assert
        (Natural (Editor.History.Undo_Stack.Length) = 1,
         "selection delete must log one undo entry");
      Assert
        (Natural (Editor.History.Redo_Stack.Length) = 0,
         "selection delete must leave redo empty after text change");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "undo must restore exact pre-delete text");
      Assert
        (Natural (Editor.History.Redo_Stack.Length) = 1,
         "undo after selection delete must create redo entry");
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "no selection delete must not mutate text");
      Assert
        (Message_Text (S) = "Nothing selected",
         "no selection delete must report deterministic no-op message");
      Assert
        (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
         "no-op selection delete must preserve redo stack");
      Assert
        (Editor.Clipboard.Get_Text = Before_Clip,
         "no-op selection delete must not mutate clipboard");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & ASCII.LF & "Gamma",
         "redo must restore exact post-delete text");
   end Test_Phase409_Selection_Delete_Undo_Redo_Clipboard_Navigation_And_No_Op;


   procedure Test_Phase410_Selection_Delete_Transform_Matrix_And_Caret


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      procedure Check
        (Before_Text  : String;
         Anchor       : Cursor_Index;
         Pos          : Cursor_Index;
         Expected     : String;
         Removed_Text : String;
         Why          : String)
      is
         S      : Editor.State.State_Type;
         Before : Unbounded_String;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Load_Text (S, Before_Text);
         Set_Primary_Selection (S, Anchor, Pos);
         Before := Editor.Selection.Extract_Selected_Text (S);
         Assert (To_String (Before) = Removed_Text,
                 Why & ": canonical selected text mismatch before delete");

         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Selection_Delete);

         Assert_Buffer_Text (S, Expected, Why);
         Assert (Message_Text (S) = "Deleted selection",
                 Why & ": message mismatch");
         Assert (not Editor.Selection.Has_Selection (S),
                 Why & ": selection must collapse after successful delete");
         Assert
           (Natural (S.Carets (S.Carets.First_Index).Pos) =
            Natural (Cursor_Index'Min (Anchor, Pos)),
            Why & ": caret must be at normalized range start");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": one undo entry expected");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert_Buffer_Text (S, Before_Text, Why & " undo restores original");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert_Buffer_Text (S, Expected, Why & " redo restores deleted text");
      end Check;
   begin
      Check ("Alpha Beta", 0, 5, " Beta", "Alpha", "whole prefix text");
      Check ("Alpha Beta", 6, 10, "Alpha ", "Beta", "whole suffix text");
      Check ("Alpha Beta", 2, 8, "Alta", "pha Be", "middle text");
      Check ("Alpha Beta", 5, 6, "AlphaBeta", " ", "space only");
      Check ("Alpha" & ASCII.HT & "Beta", 5, 6,
             "AlphaBeta", String'(1 => ASCII.HT), "tab only");
      Check ("Alpha.Beta", 5, 6, "AlphaBeta", ".", "punctuation only");
      Check ("Alpha" & ASCII.LF & "Beta", 5, 6,
             "AlphaBeta", String'(1 => ASCII.LF), "line boundary only");
      Check ("Alpha" & ASCII.LF & "Beta", 5, 10,
             "Alpha", ASCII.LF & "Beta", "boundary and following text");
      Check ("Alpha" & ASCII.LF & "Beta", 0, 6,
             "Beta", "Alpha" & ASCII.LF, "first line and boundary");
      Check ("Alpha" & ASCII.LF & ASCII.LF & "Beta", 5, 7,
             "AlphaBeta", ASCII.LF & ASCII.LF, "multiple boundaries");
      Check ("Alpha" & ASCII.LF & "  " & ASCII.LF & "Beta", 6, 9,
             "Alpha" & ASCII.LF & "Beta", "  " & ASCII.LF,
             "whitespace line");
      Check ("Alpha" & ASCII.LF & "Beta", 0, 10,
             "", "Alpha" & ASCII.LF & "Beta", "select all");
      Check ("Alpha" & ASCII.LF & "Beta", 6, 0,
             "Beta", "Alpha" & ASCII.LF,
             "backward selection matches forward selection");
   end Test_Phase410_Selection_Delete_Transform_Matrix_And_Caret;

   procedure Test_Phase410_Selection_Delete_No_Op_Invalid_And_Redo_Preservation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Redo : Natural := 0;
      Before_Dirty : Boolean := False;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha Beta");
      Editor.State.Set_Dirty (S, False);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Dirty := Editor.State.Is_Dirty (S);

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta", "no selection must not mutate text");
      Assert (Message_Text (S) = "Nothing selected",
              "no selection message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "no selection must preserve redo stack");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "no selection must preserve dirty state");

      Set_Primary_Selection (S, 3, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta", "empty selection must not mutate text");
      Assert (Message_Text (S) = "Nothing selected",
              "empty selection message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "empty selection must preserve redo stack");

      Set_Primary_Selection (S, 0, 999);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta", "invalid selection must not mutate text");
      Assert (Message_Text (S) = "Invalid selection",
              "invalid selection message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "invalid selection must preserve redo stack");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "no-op/invalid selection delete must not create undo entries");

      S.Rect_Select_Active := True;
      Set_Primary_Selection (S, 0, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "rectangular projection must not be treated as linear delete");
      Assert (Message_Text (S) = "Invalid selection",
              "rectangular selection-delete must fail deterministically");

      declare
         No_Buffer : Editor.State.State_Type;
      begin
         Editor.State.Init (No_Buffer);
         Editor.Executor.Execute_Command
           (No_Buffer, Editor.Commands.Command_Selection_Delete);
         Assert (Message_Text (No_Buffer) = "No active buffer.",
                 "no active buffer message mismatch");
      end;
   end Test_Phase410_Selection_Delete_No_Op_Invalid_And_Redo_Preservation;

   procedure Test_Phase410_Selection_Delete_Find_Dirty_Clipboard_And_Navigation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Before_Back   : Natural := 0;
      Before_Fwd    : Natural := 0;
      Before_Clip   : constant Unbounded_String := To_Unbounded_String ("CLIP");
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Find_Stale := False;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha  Gamma",
                          "selection delete must remove selected Find text");
      Assert (Editor.State.Is_Dirty (S),
              "text-changing selection delete must dirty clean buffer");
      Assert (S.Active_Find_Stale,
              "text-changing selection delete must invalidate active Find state");
      Assert (To_String (S.Active_Find_Query) = "Beta",
              "selection delete must not mutate Find query");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "selection delete must not mutate Clipboard_Text");
      Assert (Editor.Clipboard.Has_Text,
              "selection delete must not clear Clipboard_Has_Text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "selection delete caret movement must not record navigation history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert_Buffer_Text (S, "Alpha CLIP Gamma",
                          "paste after selection delete must use original clipboard");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha  Gamma",
                          "undo paste returns to post-delete text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta Gamma",
                          "undo selection delete restores exact text");

      S.Active_Find_Stale := False;
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert (not S.Active_Find_Stale,
              "no-op selection delete must not invalidate Find state");
   end Test_Phase410_Selection_Delete_Find_Dirty_Clipboard_And_Navigation;

   procedure Test_Phase410_Selection_Delete_Availability_Render_And_Persistence_Boundaries

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Text    : Unbounded_String;
      Before_Caret   : Cursor_Index;
      Before_Anchor  : Cursor_Index;
      Before_Dirty   : Boolean := False;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Availability   : Editor.Commands.Command_Availability;
      Snapshot       : Editor.Render_Model.Render_Snapshot;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      pragma Unreferenced (Snapshot);
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha Beta");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Selection (S, 0, 5);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Anchor := S.Carets (S.Carets.First_Index).Anchor;
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Selection_Delete);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "selection-delete availability must not mutate text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "selection-delete availability must not move caret");
      Assert (S.Carets (S.Carets.First_Index).Anchor = Before_Anchor,
              "selection-delete availability must not normalize selection by mutation");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "selection-delete availability must not change dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "selection-delete availability must not mutate undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "selection-delete availability must not mutate redo stack");

      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "render snapshot must not perform selection deletion");
      Assert (S.Carets (S.Carets.First_Index).Anchor = Before_Anchor,
              "render snapshot must not normalize selection by mutation");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "render snapshot must not mutate undo stack");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "selection delete") = 0
         and then Index (Summary, "deleted selection") = 0
         and then Index (Summary, "last deleted selection") = 0
         and then Index (Summary, "selection-delete") = 0
         and then Index (Summary, "kill-ring") = 0,
         "workspace persistence must exclude Selection Delete transient state");
   end Test_Phase410_Selection_Delete_Availability_Render_And_Persistence_Boundaries;

   procedure Test_Phase410_Selection_Delete_Active_Buffer_Isolation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A    : Editor.Buffers.Buffer_Id;
      B    : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Primary_Selection (S, 0, 5);
      Editor.Buffers.Ensure_Global_Registry (S);
      A := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "Gamma Delta");
      Set_Primary_Selection (S, 0, 5);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, " Beta",
                          "active buffer A selection delete text mismatch");
      Assert (not Editor.Selection.Has_Selection (S),
              "active buffer A selection must collapse after delete");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Buffer_Text (S, "Gamma Delta",
                          "inactive buffer B text must be isolated");
      Assert (Editor.Selection.Has_Selection (S),
              "inactive buffer B selection policy must remain isolated");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, " Delta",
                          "buffer B independent selection delete mismatch");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Gamma Delta",
                          "undo in B must affect only B");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Buffer_Text (S, " Beta",
                          "returning to A must preserve A delete result");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "undo in A must restore only A text");
   end Test_Phase410_Selection_Delete_Active_Buffer_Isolation;

   procedure Test_Phase410_Selection_Delete_Selection_Command_And_Edit_Coexistence

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Load_Text (S, "Alpha Beta");

      Set_Caret (S, 7);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha ",
                          "current-word selection delete must consume canonical selection");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("Beta"),
              "copy may change clipboard before selection delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "undo after current-word selection delete restores text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Clear);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "selection.clear followed by delete-selection must not infer range");
      Assert (Message_Text (S) = "Nothing selected",
              "selection.clear no-op delete message mismatch");

      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Set_Primary_Selection (S, 5, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "AlphaBeta",
                          "selection delete after line split must delete exact boundary");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & " Beta",
                          "mixed command undo restores post-split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "mixed command second undo restores original text");
   end Test_Phase410_Selection_Delete_Selection_Command_And_Edit_Coexistence;


   function Phase411_Stripped_Selected_Text
     (Marked : String) return String
   is
      Result   : String (1 .. Marked'Length) := (others => ASCII.NUL);
      Last     : Natural := 0;
      In_Range : Boolean := False;
   begin
      for I in Marked'Range loop
         if Marked (I) = '[' then
            In_Range := True;
         elsif Marked (I) = ']' then
            In_Range := False;
         else
            Last := Last + 1;
            Result (Last) := Marked (I);
         end if;
      end loop;

      if Last = 0 then
         return "";
      else
         return Result (1 .. Last);
      end if;
   end Phase411_Stripped_Selected_Text;

   function Phase411_Anchor_From_Marked
     (Marked  : String;
      Is_Reverse : Boolean) return Cursor_Index
   is
      Pos   : Natural := 0;
      Start : Natural := 0;
      Stop  : Natural := 0;
   begin
      for I in Marked'Range loop
         if Marked (I) = '[' then
            Start := Pos;
         elsif Marked (I) = ']' then
            Stop := Pos;
         else
            Pos := Pos + 1;
         end if;
      end loop;

      if Is_Reverse then
         return Cursor_Index (Stop);
      else
         return Cursor_Index (Start);
      end if;
   end Phase411_Anchor_From_Marked;

   function Phase411_Pos_From_Marked
     (Marked  : String;
      Is_Reverse : Boolean) return Cursor_Index
   is
      Pos   : Natural := 0;
      Start : Natural := 0;
      Stop  : Natural := 0;
   begin
      for I in Marked'Range loop
         if Marked (I) = '[' then
            Start := Pos;
         elsif Marked (I) = ']' then
            Stop := Pos;
         else
            Pos := Pos + 1;
         end if;
      end loop;

      if Is_Reverse then
         return Cursor_Index (Start);
      else
         return Cursor_Index (Stop);
      end if;
   end Phase411_Pos_From_Marked;

   function Phase411_Selected_Text_From_Marked
     (Marked : String) return String
   is
      Result   : String (1 .. Marked'Length) := (others => ASCII.NUL);
      Last     : Natural := 0;
      In_Range : Boolean := False;
   begin
      for I in Marked'Range loop
         if Marked (I) = '[' then
            In_Range := True;
         elsif Marked (I) = ']' then
            In_Range := False;
         elsif In_Range then
            Last := Last + 1;
            Result (Last) := Marked (I);
         end if;
      end loop;

      if Last = 0 then
         return "";
      else
         return Result (1 .. Last);
      end if;
   end Phase411_Selected_Text_From_Marked;

   procedure Phase411_Run_Marked_Delete
     (Marked   : String;
      Expected : String;
      Is_Reverse  : Boolean;
      Why      : String)
   is
      S              : Editor.State.State_Type;
      Plain          : constant String := Phase411_Stripped_Selected_Text (Marked);
      Selected       : constant String := Phase411_Selected_Text_From_Marked (Marked);
      Anchor         : constant Cursor_Index := Phase411_Anchor_From_Marked (Marked, Is_Reverse);
      Pos            : constant Cursor_Index := Phase411_Pos_From_Marked (Marked, Is_Reverse);
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Before_Dirty   : Boolean := False;
      Snapshot       : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Load_Text (S, Plain);
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Selection (S, Anchor, Pos);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Before_Dirty := Editor.State.Is_Dirty (S);

      Assert
        (To_String (Editor.Selection.Extract_Selected_Text (S)) = Selected,
         Why & ": pre-delete selected text mismatch");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);

      Assert_Buffer_Text (S, Expected, Why);
      Assert (Message_Text (S) = "Deleted selection", Why & ": message mismatch");
      Assert (not Editor.Selection.Has_Selection (S), Why & ": selection must collapse");
      Assert
        (Natural (S.Carets (S.Carets.First_Index).Pos) =
         Natural (Cursor_Index'Min (Anchor, Pos)),
         Why & ": caret must land at normalized deletion start");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              Why & ": one undo entry expected");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              Why & ": successful edit must clear redo");
      Assert (Editor.State.Is_Dirty (S) /= Before_Dirty,
              Why & ": clean buffer must become dirty after text-changing delete");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              Why & ": clipboard changed");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd, Why);

      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Assert (Snapshot.Length = Text_Buffer.Length (S.Buffer),
              Why & ": render snapshot must reflect canonical buffer length");
      Assert (Snapshot.Selection_Count = 0,
              Why & ": render snapshot must not expose stale selection");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, Plain, Why & " undo");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, Expected, Why & " redo");
   end Phase411_Run_Marked_Delete;

   procedure Test_Phase411_Selection_Delete_Workflow_Transform_Matrix

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   pragma Unreferenced (T);
   begin
      Phase411_Run_Marked_Delete ("[Alpha]", "", False, "Phase 411 whole buffer");
      Phase411_Run_Marked_Delete ("Alpha [Beta]", "Alpha ", False, "Phase 411 suffix word");
      Phase411_Run_Marked_Delete ("Al[pha Be]ta", "Alta", False, "Phase 411 middle span");
      Phase411_Run_Marked_Delete ("Alpha[ ]Beta", "AlphaBeta", False, "Phase 411 single space");
      Phase411_Run_Marked_Delete ("Alpha[" & ASCII.HT & "]Beta", "AlphaBeta", False, "Phase 411 tab");
      Phase411_Run_Marked_Delete ("Alpha[, ]Beta", "AlphaBeta", False, "Phase 411 punctuation space");
      Phase411_Run_Marked_Delete ("[Alpha]" & ASCII.LF & "Beta", ASCII.LF & "Beta", False, "Phase 411 prefix before line boundary");
      Phase411_Run_Marked_Delete ("Alpha" & ASCII.LF & "[Beta]", "Alpha" & ASCII.LF, False, "Phase 411 second line");
      Phase411_Run_Marked_Delete ("Alpha[" & ASCII.LF & "]Beta", "AlphaBeta", False, "Phase 411 boundary only");
      Phase411_Run_Marked_Delete ("Alpha[" & ASCII.LF & "Beta]", "Alpha", False, "Phase 411 boundary and text");
      Phase411_Run_Marked_Delete ("[Alpha" & ASCII.LF & "]Beta", "Beta", False, "Phase 411 first line including boundary");
      Phase411_Run_Marked_Delete ("Alpha[" & ASCII.LF & ASCII.LF & "]Beta", "AlphaBeta", False, "Phase 411 blank line boundary pair");
      Phase411_Run_Marked_Delete ("Alpha" & ASCII.LF & "[  " & ASCII.LF & "]Beta", "Alpha" & ASCII.LF & "Beta", False, "Phase 411 whitespace line");
      Phase411_Run_Marked_Delete ("[Alpha" & ASCII.LF & "Beta" & ASCII.LF & "]", "", False, "Phase 411 trailing newline full buffer");
      Phase411_Run_Marked_Delete ("Alpha" & ASCII.LF & "[Beta" & ASCII.LF & "]", "Alpha" & ASCII.LF, False, "Phase 411 trailing newline suffix");
   end Test_Phase411_Selection_Delete_Workflow_Transform_Matrix;

   procedure Test_Phase411_Forward_Backward_Equivalence_And_Invalid_Noops

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      procedure Check_Equivalence (Marked : String; Expected : String; Why : String) is
         F : Editor.State.State_Type;
         B : Editor.State.State_Type;
         Plain    : constant String := Phase411_Stripped_Selected_Text (Marked);
         F_Anchor : constant Cursor_Index := Phase411_Anchor_From_Marked (Marked, False);
         F_Pos    : constant Cursor_Index := Phase411_Pos_From_Marked (Marked, False);
         B_Anchor : constant Cursor_Index := Phase411_Anchor_From_Marked (Marked, True);
         B_Pos    : constant Cursor_Index := Phase411_Pos_From_Marked (Marked, True);
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Load_Text (F, Plain);
         Set_Primary_Selection (F, F_Anchor, F_Pos);
         Editor.Executor.Execute_Command (F, Editor.Commands.Command_Selection_Delete);

         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Load_Text (B, Plain);
         Set_Primary_Selection (B, B_Anchor, B_Pos);
         Editor.Executor.Execute_Command (B, Editor.Commands.Command_Selection_Delete);

         Assert_Buffer_Text (F, Expected, Why & " forward");
         Assert_Buffer_Text (B, Expected, Why & " backward");
         Assert (F.Carets (F.Carets.First_Index).Pos = B.Carets (B.Carets.First_Index).Pos,
                 Why & ": caret differs");
         Assert (F.Carets (F.Carets.First_Index).Anchor = B.Carets (B.Carets.First_Index).Anchor,
                 Why & ": anchor differs");
         Assert (not Editor.Selection.Has_Selection (F)
                 and then not Editor.Selection.Has_Selection (B),
                 Why & ": selection not collapsed");
      end Check_Equivalence;

      S           : Editor.State.State_Type;
      Before_Redo : Natural := 0;
      Before_Undo : Natural := 0;
   begin
      Check_Equivalence ("Alpha [Beta]", "Alpha ", "Phase 411 word equivalence");
      Check_Equivalence ("Al[pha Be]ta", "Alta", "Phase 411 middle equivalence");
      Check_Equivalence ("Alpha[  ]Beta", "AlphaBeta", "Phase 411 whitespace equivalence");
      Check_Equivalence ("Alpha[,] Beta", "Alpha Beta", "Phase 411 punctuation equivalence");
      Check_Equivalence ("Alpha[" & ASCII.LF & "]Beta", "AlphaBeta", "Phase 411 boundary equivalence");
      Check_Equivalence ("[Alpha" & ASCII.LF & "Beta]", "", "Phase 411 cross-line equivalence");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta", "Phase 411 no selection no-op text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 411 no selection must preserve redo");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "Phase 411 no selection must not create undo");

      Set_Primary_Selection (S, 3, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta", "Phase 411 empty selection no-op text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 411 empty selection must preserve redo");

      Set_Primary_Selection (S, 0, 999);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta", "Phase 411 invalid selection no-op text");
      Assert (Message_Text (S) = "Invalid selection",
              "Phase 411 invalid selection message");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 411 invalid selection must preserve redo");
   end Test_Phase411_Forward_Backward_Equivalence_And_Invalid_Noops;

   procedure Test_Phase411_Undo_Redo_Dirty_Find_Clipboard_And_Navigation_Workflow

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Before_Redo    : Natural := 0;
      Snapshot       : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Prompt := True;
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Find_Stale := False;
      S.Active_Replace_Prompt := True;
      S.Active_Replace_Text := To_Unbounded_String ("DELTA");
      Set_Primary_Selection (S, 6, 10);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha  Gamma", "Phase 411 find workflow delete");
      Assert (Editor.State.Is_Dirty (S), "Phase 411 delete must dirty clean buffer");
      Assert (S.Active_Find_Stale, "Phase 411 delete must stale active Find");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Phase 411 delete must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("DELTA"),
              "Phase 411 delete must not mutate Replace text");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 411 delete must not mutate Clipboard");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "Phase 411 delete navigation boundary");
      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Assert (Snapshot.Find_Matches_Stale,
              "Phase 411 render must expose stale/current Find policy after edit");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta Gamma", "Phase 411 undo restores text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 411 undo creates redo");
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Set_Caret (S, 0);
      S.Active_Find_Stale := False;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 411 no-op delete preserves redo after undo");
      Assert (not S.Active_Find_Stale,
              "Phase 411 no-op delete must not stale Find");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha  Gamma", "Phase 411 redo restores delete");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 411 redo path still not clipboard-owned");
   end Test_Phase411_Undo_Redo_Dirty_Find_Clipboard_And_Navigation_Workflow;

   procedure Test_Phase411_Command_Coexistence_And_Cut_Contrast

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Load_Text (S, "Alpha Beta Gamma");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "", "Phase 411 select-all delete");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 411 select-all delete must not copy deleted text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Caret (S, 7);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha  Gamma", "Phase 411 current-word delete");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("Beta"),
              "Phase 411 copy before delete owns clipboard mutation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Assert_Buffer_Text (S, "Alpha  Gamma", "Phase 411 cut text effect");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("Beta"),
              "Phase 411 cut owns clipboard mutation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Gamma", "Phase 411 after char delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Word_Delete_Next);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "", "Phase 411 after word delete select-all");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Set_Primary_Selection (S, 5, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta Gamma", "Phase 411 after line split boundary delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Set_Primary_Selection (S, 5, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta Gamma", "Phase 411 after line join");
   end Test_Phase411_Command_Coexistence_And_Cut_Contrast;

   procedure Test_Phase411_Read_Only_Routes_Feature_And_Persistence_Boundaries

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Text    : Unbounded_String;
      Before_Caret   : Cursor_Index;
      Before_Anchor  : Cursor_Index;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("CLIP");
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Availability   : Editor.Commands.Command_Availability;
      Snapshot       : Editor.Render_Model.Render_Snapshot;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Found          : Boolean := False;
      Dummy          : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      procedure Assert_Not_Exposed (Name : String) is
      begin
         Dummy := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found, "Phase 411 non-goal command exposed: " & Name);
      end Assert_Not_Exposed;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Load_Text (S, "Alpha Beta");
      S.Active_Find_Query := To_Unbounded_String ("Alpha");
      S.Active_Replace_Text := To_Unbounded_String ("Omega");
      S.Active_Find_Prompt := True;
      S.Active_Replace_Prompt := True;
      Set_Primary_Selection (S, 0, 5);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Anchor := S.Carets (S.Carets.First_Index).Anchor;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Selection_Delete);
      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;

      Assert_Buffer_Text (S, To_String (Before_Text), "Phase 411 read-only routes text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "Phase 411 read-only routes moved caret");
      Assert (S.Carets (S.Carets.First_Index).Anchor = Before_Anchor,
              "Phase 411 read-only routes normalized selection by mutation");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "Phase 411 read-only routes mutated undo");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 411 read-only routes mutated redo");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 411 read-only routes mutated clipboard");
      Assert (Snapshot.Selection_Count = 1,
              "Phase 411 render should project, not consume, canonical selection");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "selection delete") = 0
         and then Index (Summary, "deleted selection") = 0
         and then Index (Summary, "last deleted selection") = 0
         and then Index (Summary, "selection-delete") = 0
         and then Index (Summary, "kill-ring") = 0
         and then Index (Summary, "clipboard mirror") = 0,
         "Phase 411 workspace persistence must exclude Selection Delete transient state");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Alpha"),
              "Phase 411 delete must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Omega"),
              "Phase 411 delete must not mutate Replace text");

      Assert_Not_Exposed ("edit.selection.cut");
      Assert_Not_Exposed ("edit.selection.kill");
      Assert_Not_Exposed ("edit.selection.delete-lines");
      Assert_Not_Exposed ("edit.selection.delete-rect");
      Assert_Not_Exposed ("edit.selection.delete-block");
      Assert_Not_Exposed ("edit.selection.delete-semantic-node");
      Assert_Not_Exposed ("edit.text.delete-range");
      Assert_Not_Exposed ("edit.multi-cursor.delete-selection");
   end Test_Phase411_Read_Only_Routes_Feature_And_Persistence_Boundaries;


procedure Test_Phase412_Selection_Delete_Canonical_State_Only_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      After          : Editor.State.State_Type;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("KEEP-ME");
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Chord          : Editor.Keybindings.Key_Chord;
      Found_Chord    : Boolean := False;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Replace_Text := To_Unbounded_String ("Delta");
      Set_Primary_Selection (S, 6, 10);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Chord := Editor.Keybindings.Parse_Chord ("Ctrl+Alt+M", Found_Chord);
      Assert (Found_Chord, "Phase 412 test chord must parse");
      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Selection_Delete);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert_Buffer_Text
        (After, "Alpha  Gamma",
         "Phase 412 Input_Bridge must route canonical Selection Delete through Executor");
      Assert (Message_Text (After) = "Deleted selection",
              "Phase 412 Selection Delete message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 412 Selection Delete must create one undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 412 text-changing Selection Delete must clear redo only after success");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Phase 412 Selection Delete must not mutate Clipboard text");
      Assert (Editor.Clipboard.Has_Text,
              "Phase 412 Selection Delete must not clear Clipboard state");
      Assert (After.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Phase 412 Selection Delete must not mutate Find query");
      Assert (After.Active_Replace_Text = To_Unbounded_String ("Delta"),
              "Phase 412 Selection Delete must not mutate Replace text");
      Assert_Navigation_Counts
        (After, Before_Back, Before_Fwd,
         "Phase 412 Selection Delete must not record navigation history");
      Assert (not Editor.Selection.Has_Selection (After),
              "Phase 412 successful Selection Delete must clear/collapse selection");

      Editor.Executor.Execute_Command (After, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (After, "Alpha Beta Gamma",
         "Phase 412 undo must restore captured Selection Delete Before_Text");
      Editor.Executor.Execute_Command (After, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (After, "Alpha  Gamma",
         "Phase 412 redo must restore captured Selection Delete After_Text");

      Workspace := Editor.State.Build_Workspace_Snapshot (After);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "selection delete") = 0
         and then Index (Summary, "deleted selection") = 0
         and then Index (Summary, "last deleted selection") = 0
         and then Index (Summary, "selection-delete") = 0
         and then Index (Summary, "selected-range cache") = 0
         and then Index (Summary, "clipboard mirror") = 0
         and then Index (Summary, "kill-ring") = 0,
         "Phase 412 persistence must exclude canonical and removed Selection Delete state");

      Editor.Keybindings.Reset_To_Defaults;
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Phase412_Selection_Delete_Canonical_State_Only_Workflow;



   procedure Execute_Text_Input
     (S       : in out Editor.State.State_Type;
      Payload : String)
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Text := To_Unbounded_String (Payload);
      Editor.Executor.Execute_No_Log (S, Cmd);
   end Execute_Text_Input;

   procedure Test_Phase413_Text_Insert_Basic_Caret_And_Undo

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 2);

      Execute_Text_Input (S, "X");

      Assert_Buffer_Text (S, "AlXpha", "Phase 413 insert in middle");
      Assert (S.Carets (S.Carets.First_Index).Pos = 3,
              "Phase 413 insert moves caret to payload end");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 413 insert leaves no selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 413 insert creates one undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 413 insert leaves redo empty");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 413 insert dirties clean buffer");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha", "Phase 413 undo restores text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "AlXpha", "Phase 413 redo restores inserted text");
   end Test_Phase413_Text_Insert_Basic_Caret_And_Undo;

   procedure Test_Phase413_Text_Insert_Replaces_Selection_Without_Clipboard

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Selection (S, 6, 10);

      Execute_Text_Input (S, "Gamma");

      Assert_Buffer_Text (S, "Alpha Gamma", "Phase 413 selection replacement");
      Assert (S.Carets (S.Carets.First_Index).Pos = 11,
              "Phase 413 replacement caret at insert end");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 413 replacement clears selection");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 413 replacement leaves clipboard untouched");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 413 replacement creates one undo entry");
   end Test_Phase413_Text_Insert_Replaces_Selection_Without_Clipboard;

   procedure Test_Phase413_Input_Bridge_Routes_Editor_Text_And_Protects_Overlays

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 0);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'A';
      Cmd.Text := To_Unbounded_String (String'(1 => 'A'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('A'));
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text (S, "ABeta", "Phase 413 bridge routes editor text input");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 413 bridge insertion uses undoable mutation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Quick_Open);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('Z'));
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text (S, "ABeta", "Phase 413 overlay text input does not edit buffer");
   end Test_Phase413_Input_Bridge_Routes_Editor_Text_And_Protects_Overlays;


   procedure Test_Phase413_Completeness_Noop_Invalid_And_Redo_Boundaries


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Selection (S, 0, 5);

      Execute_Text_Input (S, "");
      Assert_Buffer_Text (S, "Alpha", "Phase 413 empty payload no-op preserves text");
      Assert (Editor.Selection.Has_Selection (S),
              "Phase 413 empty payload no-op preserves valid selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 413 empty payload creates no undo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 413 empty payload leaves clean buffer clean");

      Execute_Text_Input (S, String'(1 => ASCII.NUL));
      Assert_Buffer_Text (S, "Alpha", "Phase 413 invalid NUL payload preserves text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 413 invalid payload creates no undo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 413 invalid payload leaves dirty state unchanged");

      Set_Caret (S, 5);
      Execute_Text_Input (S, "!");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha", "Phase 413 undo before redo preservation setup");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 413 undo leaves one redo entry before no-op");

      Execute_Text_Input (S, "");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 413 no-op after undo preserves redo stack");
      Execute_Text_Input (S, String'(1 => ASCII.NUL));
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 413 invalid input after undo preserves redo stack");

      Execute_Text_Input (S, "?");
      Assert_Buffer_Text (S, "Alpha?", "Phase 413 successful insert after undo applies text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 413 successful insert after undo clears redo stack");
   end Test_Phase413_Completeness_Noop_Invalid_And_Redo_Boundaries;

   procedure Test_Phase413_Completeness_Backward_Cross_Line_Replacement_And_Persistence

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
      Workspace   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary     : Unbounded_String;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma");
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Replace_Text := To_Unbounded_String ("Delta");
      Set_Primary_Selection (S, 10, 2);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Execute_Text_Input (S, "X");

      Assert_Buffer_Text
        (S, "AlX" & ASCII.LF & "Gamma",
         "Phase 413 backward cross-line selection replacement");
      Assert (S.Carets (S.Carets.First_Index).Pos = 3,
              "Phase 413 cross-line replacement caret ends after payload");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 413 cross-line replacement clears selection");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 413 replacement does not read or mutate Clipboard text");
      Assert (Editor.Clipboard.Has_Text,
              "Phase 413 replacement does not clear Clipboard presence");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Phase 413 Text Insert must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Delta"),
              "Phase 413 Text Insert must not mutate Replace text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 413 Text Insert must not record Navigation History");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 413 selection replacement creates one undo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "Phase 413 undo restores cross-line replacement text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "AlX" & ASCII.LF & "Gamma",
         "Phase 413 redo restores cross-line replacement text");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "text insert") = 0
         and then Index (Summary, "last inserted text") = 0
         and then Index (Summary, "last inserted range") = 0
         and then Index (Summary, "input payload history") = 0
         and then Index (Summary, "typed text history") = 0
         and then Index (Summary, "internal.text.insert") = 0,
         "Phase 413 persistence must exclude Text Insert transient state");
   end Test_Phase413_Completeness_Backward_Cross_Line_Replacement_And_Persistence;

   procedure Test_Phase413_Completeness_Unicode_Routing_Internal_Surface_And_Isolation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Lambda     : constant Editor.Unicode.Code_Point :=
        Wide_Wide_Character'Val (16#03BB#);
      Found      : Boolean := False;
      Resolved   : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      A_Id       : Editor.Buffers.Buffer_Id;
      B_Id       : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A");
      Set_Caret (S, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Code := Lambda;
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;

      Assert_Buffer_Text
        (S, "A" & Editor.UTF8.Encode_UTF8 (Lambda),
         "Phase 413 bridge must route non-Latin text through canonical Text Insert");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 413 unicode text entry creates one undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 413 unicode text entry does not create redo entries");

      Resolved :=
        Editor.Commands.Command_Id_From_Stable_Name ("internal.text.insert", Found);
      Assert (not Found and then Resolved = Editor.Commands.No_Command,
              "Phase 413 arbitrary parameterized Text Insert must not be a public stable command");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 4);
      Execute_Text_Input (S, "!");
      Assert_Buffer_Text (S, "Beta!",
                          "Phase 413 insert mutates the active buffer");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text (S, "Alpha",
                          "Phase 413 insert must not mutate inactive buffers");
      Assert (Editor.History.Undo_Stack.Is_Empty,
              "Phase 413 inactive buffer must not inherit text-insert undo entries");

      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text (S, "Beta!",
                          "Phase 413 switched active buffer preserves inserted text");
      Assert (not Editor.History.Undo_Stack.Is_Empty,
              "Phase 413 active buffer retains its own text-insert undo entry");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      S.Carets.Clear;
      Execute_Text_Input (S, "X");
      Assert_Buffer_Text (S, "Beta!",
                          "Phase 413 no-caret text insert must not mutate text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 413 no-caret text insert creates no undo entry");
   end Test_Phase413_Completeness_Unicode_Routing_Internal_Surface_And_Isolation;


   procedure Test_Phase413_Remove_Removed_Name_Text_Input_Uses_Canonical_Path


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Find_Stale := False;
      Set_Primary_Selection (S, 6, 10);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'X';
      Cmd.Text := To_Unbounded_String (String'(1 => 'X'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('X'));
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert_Buffer_Text
        (S, "Alpha X",
         "Phase 413 canonical Text Insert must use canonical selection replacement");
      Assert (S.Carets (S.Carets.First_Index).Pos = 7,
              "Phase 413 canonical Text Insert replacement moves caret to payload end");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 413 canonical Text Insert replacement clears selection");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 413 canonical Text Insert canonical path does not touch Clipboard");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Phase 413 canonical Text Insert must not mutate Find query text");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Phase 413 canonical Text Insert must invalidate Find through text-edit hook");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 413 canonical Text Insert must not record Navigation History");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 413 canonical Text Insert creates exactly one undo entry");
   end Test_Phase413_Remove_Removed_Name_Text_Input_Uses_Canonical_Path;

   procedure Test_Phase413_Completeness_Line_Boundary_Command_Is_Canonical_Insert

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Find_Stale := False;
      Set_Caret (S, 5);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Insert_Newline);

      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "Phase 413 Insert Newline command must normalize through canonical Text Insert");
      Assert (S.Carets (S.Carets.First_Index).Pos = 6,
              "Phase 413 line-boundary payload moves caret after canonical boundary");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 413 line-boundary insertion creates one undo entry");
      Assert (S.Active_Find_Stale,
              "Phase 413 line-boundary insertion invalidates Find through text-edit hook");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "Phase 413 undo restores text before line-boundary insertion");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "Phase 413 redo restores exact line-boundary payload");
   end Test_Phase413_Completeness_Line_Boundary_Command_Is_Canonical_Insert;

   procedure Test_Phase413_Completeness_Multi_Caret_Insert_Is_Not_Second_Model

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, 0);
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => 6,
            Anchor                => 6,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'X';
      Cmd.Text := To_Unbounded_String (String'(1 => 'X'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('X'));
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert_Buffer_Text
        (S, "Alpha Beta",
         "Phase 413 direct multi-caret Insert_Text_Input must be rejected by the canonical single-caret path");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 413 rejected multi-caret insertion creates no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 413 rejected multi-caret insertion creates no redo entry");
   end Test_Phase413_Completeness_Multi_Caret_Insert_Is_Not_Second_Model;

   procedure Test_Phase414_Text_Insert_Caret_Transform_Matrix

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      procedure Case_Insert
        (Before         : String;
         Caret_Pos      : Cursor_Index;
         Payload        : String;
         Expected       : String;
         Expected_Caret : Cursor_Index;
         Why            : String)
      is
         S : Editor.State.State_Type;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Before);
         Editor.State.Set_Dirty (S, False);
         Set_Caret (S, Caret_Pos);

         Execute_Text_Input (S, Payload);

         Assert_Buffer_Text (S, Expected, Why);
         Assert (S.Carets (S.Carets.First_Index).Pos = Expected_Caret,
                 Why & ": caret must end after inserted payload");
         Assert (not Editor.Selection.Has_Selection (S),
                 Why & ": insertion must leave no active selection");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": insertion must create exactly one undo entry");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": insertion must not create redo entries");
         Assert (Editor.State.Is_Dirty (S),
                 Why & ": insertion must dirty a clean buffer");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert_Buffer_Text (S, Before, Why & ": undo restores before text");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert_Buffer_Text (S, Expected, Why & ": redo restores inserted text");
      end Case_Insert;
   begin
      Case_Insert ("Beta", 0, "A", "ABeta", 1,
                   "Phase 414 insert at buffer start");
      Case_Insert ("Alpha", 5, "!", "Alpha!", 6,
                   "Phase 414 insert at buffer end");
      Case_Insert ("Alpha", 2, "X", "AlXpha", 3,
                   "Phase 414 insert in middle of ordinary text");
      Case_Insert ("Alpha Beta", 6, "_", "Alpha _Beta", 7,
                   "Phase 414 insert adjacent to whitespace");
      Case_Insert ("Alpha.Beta", 5, ".", "Alpha..Beta", 6,
                   "Phase 414 insert adjacent to punctuation");
      Case_Insert ("", 0, "A", "A", 1,
                   "Phase 414 insert into empty buffer");
      Case_Insert ("AlphaBeta", 5, "123", "Alpha123Beta", 8,
                   "Phase 414 insert multi-character payload");
      Case_Insert ("AlphaBeta", 5, " ", "Alpha Beta", 6,
                   "Phase 414 insert literal space payload");
      Case_Insert ("AlphaBeta", 5, String'(1 => ASCII.HT),
                   "Alpha" & ASCII.HT & "Beta", 6,
                   "Phase 414 insert literal tab payload");
      Case_Insert ("AlphaBeta", 5, String'(1 => ASCII.LF),
                   "Alpha" & ASCII.LF & "Beta", 6,
                   "Phase 414 insert canonical line-boundary payload");
   end Test_Phase414_Text_Insert_Caret_Transform_Matrix;


   procedure Test_Phase414_Text_Insert_Replacement_Transform_Matrix


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      procedure Case_Replace
        (Before         : String;
         Anchor_Pos     : Cursor_Index;
         Focus_Pos      : Cursor_Index;
         Payload        : String;
         Expected       : String;
         Expected_Caret : Cursor_Index;
         Why            : String)
      is
         S : Editor.State.State_Type;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Before);
         Editor.State.Set_Dirty (S, False);
         Set_Primary_Selection (S, Anchor_Pos, Focus_Pos);

         Execute_Text_Input (S, Payload);

         Assert_Buffer_Text (S, Expected, Why);
         Assert (S.Carets (S.Carets.First_Index).Pos = Expected_Caret,
                 Why & ": caret must end after inserted payload");
         Assert (not Editor.Selection.Has_Selection (S),
                 Why & ": replacement must clear/collapse selection");
         Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
                 Why & ": replacement must not mutate Clipboard text");
         Assert (Editor.Clipboard.Has_Text,
                 Why & ": replacement must not clear Clipboard presence");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
                 Why & ": replacement must create exactly one undo entry");
         Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
                 Why & ": replacement must not create redo entries");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert_Buffer_Text (S, Before, Why & ": undo restores selected text");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert_Buffer_Text (S, Expected, Why & ": redo restores replacement");
      end Case_Replace;
   begin
      Case_Replace ("Alpha", 0, 5, "Beta", "Beta", 4,
                    "Phase 414 replace select-all");
      Case_Replace ("Alpha Beta", 6, 10, "Gamma", "Alpha Gamma", 11,
                    "Phase 414 replace single-line selection");
      Case_Replace ("Alpha Beta", 8, 3, "X", "AlpXta", 4,
                    "Phase 414 replace backward selection equivalently");
      Case_Replace ("Alpha Beta", 5, 6, "_", "Alpha_Beta", 6,
                    "Phase 414 replace whitespace selection");
      Case_Replace ("Alpha.Beta", 5, 6, "!", "Alpha!Beta", 6,
                    "Phase 414 replace punctuation selection");
      Case_Replace ("Alpha" & ASCII.HT & "Beta", 5, 6, " ",
                    "Alpha Beta", 6,
                    "Phase 414 replace tab selection");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 5, 6, " ",
                    "Alpha Beta", 6,
                    "Phase 414 replace line-boundary-only selection");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 0, 6, "X",
                    "XBeta", 1,
                    "Phase 414 replace through first line boundary");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 5, 10, "X",
                    "AlphaX", 6,
                    "Phase 414 replace through trailing selected text");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 0, 10, "X",
                    "X", 1,
                    "Phase 414 replace cross-line select-all");
   end Test_Phase414_Text_Insert_Replacement_Transform_Matrix;


   procedure Test_Phase414_Text_Insert_Noop_Invalid_And_Redo_Are_NonMutating


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("Alpha");
      S.Active_Find_Stale := False;
      Set_Caret (S, 5);
      Execute_Text_Input (S, "!");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Set_Primary_Selection (S, 0, 5);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Execute_Text_Input (S, "");
      Assert_Buffer_Text (S, "Alpha", "Phase 414 empty payload preserves text");
      Assert (Editor.Selection.Has_Selection (S),
              "Phase 414 empty payload preserves valid selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 414 empty payload creates no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 414 empty payload preserves redo stack");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 414 empty payload preserves dirty state");
      Assert (not S.Active_Find_Stale,
              "Phase 414 empty payload must not invalidate Find state");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 414 empty payload leaves Clipboard text untouched");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "Phase 414 empty payload records no navigation");

      Execute_Text_Input (S, String'(1 => ASCII.NUL));
      Assert_Buffer_Text (S, "Alpha", "Phase 414 NUL payload preserves text");
      Assert (Editor.Selection.Has_Selection (S),
              "Phase 414 NUL payload preserves selection");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 414 NUL payload preserves redo stack");
      Assert (not S.Active_Find_Stale,
              "Phase 414 NUL payload must not invalidate Find state");

      Execute_Text_Input (S, String'(1 => ASCII.CR));
      Assert_Buffer_Text (S, "Alpha", "Phase 414 CR payload preserves text");
      Assert (Editor.Selection.Has_Selection (S),
              "Phase 414 CR payload preserves selection");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 414 CR payload preserves redo stack");

      Execute_Text_Input (S, String'(1 => ASCII.ESC));
      Assert_Buffer_Text (S, "Alpha", "Phase 414 ESC payload preserves text");
      Assert (Editor.Selection.Has_Selection (S),
              "Phase 414 ESC payload preserves selection");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 414 ESC payload preserves redo stack");
   end Test_Phase414_Text_Insert_Noop_Invalid_And_Redo_Are_NonMutating;


   procedure Test_Phase414_Text_Insert_Invalid_Selection_Does_Not_Repair_State


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, 0);
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => 6,
            Anchor                => 6,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Execute_Text_Input (S, "X");

      Assert_Buffer_Text
        (S, "Alpha Beta",
         "Phase 414 invalid multi-caret Text Insert must not mutate text");
      Assert (Natural (S.Carets.Length) = 2,
              "Phase 414 invalid multi-caret Text Insert must not collapse carets");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 414 invalid multi-caret Text Insert creates no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 414 invalid multi-caret Text Insert creates no redo entry");

      S.Rect_Select_Active := True;
      Execute_Text_Input (S, "Y");
      Assert_Buffer_Text
        (S, "Alpha Beta",
         "Phase 414 rectangular Text Insert failure must not mutate text");
      Assert (Natural (S.Carets.Length) = 2,
              "Phase 414 rectangular Text Insert failure must not repair carets");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 414 rectangular Text Insert failure creates no undo entry");
   end Test_Phase414_Text_Insert_Invalid_Selection_Does_Not_Repair_State;


   procedure Test_Phase414_Text_Insert_Find_Clipboard_Navigation_And_Persistence


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
      Workspace   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary     : Unbounded_String;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Replace_Text := To_Unbounded_String ("Gamma");
      S.Active_Find_Stale := False;
      Set_Caret (S, 6);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Execute_Text_Input (S, "X");

      Assert_Buffer_Text (S, "Alpha XBeta", "Phase 414 insert before find match");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Phase 414 Text Insert does not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Gamma"),
              "Phase 414 Text Insert does not mutate Replace text");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Phase 414 Text Insert invalidates Find through canonical text-edit hook");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 414 Text Insert does not mutate Clipboard text");
      Assert (Editor.Clipboard.Has_Text,
              "Phase 414 Text Insert does not clear Clipboard presence");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Phase 414 Text Insert records no Navigation History");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "text insert") = 0
         and then Index (Summary, "last inserted text") = 0
         and then Index (Summary, "last inserted range") = 0
         and then Index (Summary, "last replacement range") = 0
         and then Index (Summary, "typed text history") = 0
         and then Index (Summary, "input payload history") = 0,
         "Phase 414 persistence must exclude Text Insert transient state");
   end Test_Phase414_Text_Insert_Find_Clipboard_Navigation_And_Persistence;


   procedure Test_Phase414_Completeness_Active_Buffer_Render_And_Overlay_Routing


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Cmd            : Editor.Commands.Command;
      A_Id           : Editor.Buffers.Buffer_Id;
      B_Id           : Editor.Buffers.Buffer_Id;
      Snap           : Editor.Render_Model.Render_Snapshot;
      Undo_Before    : Natural := 0;
      Redo_Before    : Natural := 0;
      Dirty_Before   : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, 5);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 4);
      Execute_Text_Input (S, "!");
      Assert_Buffer_Text
        (S, "Beta!",
         "Phase 414 completeness Text Insert mutates only active buffer B");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 414 completeness active buffer B receives one undo entry");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text
        (S, "Alpha",
         "Phase 414 completeness inactive buffer A remains unchanged");
      Assert (Editor.History.Undo_Stack.Is_Empty,
              "Phase 414 completeness inactive buffer A has no Text Insert undo entry");

      Set_Caret (S, 0);
      Execute_Text_Input (S, "A");
      Assert_Buffer_Text
        (S, "AAlpha",
         "Phase 414 completeness buffer A can be edited independently after switch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 414 completeness buffer A has its own undo entry");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text
        (S, "Beta!",
         "Phase 414 completeness buffer B retains independent inserted text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Beta",
         "Phase 414 completeness undo in buffer B affects only buffer B");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text
        (S, "AAlpha",
         "Phase 414 completeness undo in B does not change buffer A");

      --  Rendering observes current text/caret state only.  It must not repair,
      --  insert, clear redo, mutate dirty state, or produce editor text-entry
      --  side effects.
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 414 completeness render snapshot reflects buffer length");
      Assert_Buffer_Text
        (S, "AAlpha",
         "Phase 414 completeness render snapshot must not insert text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 414 completeness render snapshot must not mutate undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 414 completeness render snapshot must not mutate redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "Phase 414 completeness render snapshot must not mutate dirty state");

      --  Input_Bridge editor focus routes to canonical Text Insert, while an
      --  overlay/input owner consumes text locally before the active buffer can
      --  be touched.
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Core");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 2);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'X';
      Cmd.Text := To_Unbounded_String (String'(1 => 'X'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('X'));
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (S, "CoXre",
         "Phase 414 completeness bridge editor focus routes through Text Insert");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 414 completeness bridge editor text creates one undo entry");

      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Quick_Open);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('Z'));
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (S, "CoXre",
         "Phase 414 completeness Quick Open text input must not leak into buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 414 completeness overlay text input must not create buffer undo entries");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 414 completeness overlay text input must not mutate buffer redo entries");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "Phase 414 completeness overlay text input must not mutate buffer dirty state");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase414_Completeness_Active_Buffer_Render_And_Overlay_Routing;


   procedure Assert_Text_Insert_Coherent
     (S                   : Editor.State.State_Type;
      Expected_Text       : String;
      Expected_Caret      : Cursor_Index;
      Expected_Undo_Count : Natural;
      Expected_Redo_Count : Natural;
      Expected_Dirty      : Boolean;
      Expected_Clipboard  : Unbounded_String;
      Expected_Back_Count : Natural;
      Expected_Fwd_Count  : Natural;
      Why                 : String)
   is
   begin
      Assert_Buffer_Text (S, Expected_Text, Why);
      Assert (S.Carets.Length = 1, Why & ": expected exactly one primary caret");
      Assert (S.Carets (S.Carets.First_Index).Pos = Expected_Caret,
              Why & ": caret must end at canonical inserted payload end");
      Assert (not Editor.Selection.Has_Selection (S),
              Why & ": successful Text Insert must clear/collapse selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Expected_Undo_Count,
              Why & ": undo stack count mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Expected_Redo_Count,
              Why & ": redo stack count mismatch");
      Assert (Editor.State.Is_Dirty (S) = Expected_Dirty,
              Why & ": dirty state mismatch");
      Assert (Editor.Clipboard.Get_Text = Expected_Clipboard,
              Why & ": Text Insert must not mutate Clipboard text");
      Assert_Navigation_Counts (S, Expected_Back_Count, Expected_Fwd_Count, Why);
   end Assert_Text_Insert_Coherent;


   procedure Test_Phase415_Text_Insert_Workflow_Transform_And_Replacement


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      procedure Case_Insert
        (Before         : String;
         Caret_Pos      : Cursor_Index;
         Payload        : String;
         Expected       : String;
         Expected_Caret : Cursor_Index;
         Why            : String)
      is
         S           : Editor.State.State_Type;
         Before_Back : Natural := 0;
         Before_Fwd  : Natural := 0;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Before);
         Editor.State.Set_Dirty (S, False);
         S.Active_Find_Query := To_Unbounded_String ("a");
         S.Active_Replace_Text := To_Unbounded_String ("r");
         S.Active_Find_Stale := False;
         Set_Caret (S, Caret_Pos);
         Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
         Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

         Execute_Text_Input (S, Payload);

         Assert_Text_Insert_Coherent
           (S, Expected, Expected_Caret, 1, 0, True,
            To_Unbounded_String ("CLIP"), Before_Back, Before_Fwd, Why);
         Assert (S.Active_Find_Query = To_Unbounded_String ("a"),
                 Why & ": Text Insert must not mutate Find query");
         Assert (S.Active_Replace_Text = To_Unbounded_String ("r"),
                 Why & ": Text Insert must not mutate Replace text");
         Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
                 Why & ": text-changing insertion invalidates Find through canonical hook");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert_Buffer_Text (S, Before, Why & ": undo restores exact pre-insert text");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert_Buffer_Text (S, Expected, Why & ": redo restores exact inserted text");
      end Case_Insert;

      procedure Case_Replace
        (Before         : String;
         Anchor_Pos     : Cursor_Index;
         Focus_Pos      : Cursor_Index;
         Payload        : String;
         Expected       : String;
         Expected_Caret : Cursor_Index;
         Removed        : String;
         Why            : String)
      is
         S           : Editor.State.State_Type;
         Before_Back : Natural := 0;
         Before_Fwd  : Natural := 0;
      begin
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
         Editor.State.Init (S);
         Editor.State.Load_Text (S, Before);
         Editor.State.Set_Dirty (S, False);
         S.Active_Find_Query := To_Unbounded_String (Removed);
         S.Active_Replace_Text := To_Unbounded_String ("replacement text remains independent");
         S.Active_Find_Stale := False;
         Set_Primary_Selection (S, Anchor_Pos, Focus_Pos);
         Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
         Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

         Execute_Text_Input (S, Payload);

         Assert_Text_Insert_Coherent
           (S, Expected, Expected_Caret, 1, 0, True,
            To_Unbounded_String ("CLIP"), Before_Back, Before_Fwd, Why);
         Assert (S.Active_Find_Query = To_Unbounded_String (Removed),
                 Why & ": replacement must not rewrite Find query");
         Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
                 Why & ": replacement invalidates stale Find ranges");

         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
         Assert_Buffer_Text (S, Before, Why & ": undo restores selected text exactly");
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
         Assert_Buffer_Text (S, Expected, Why & ": redo restores replacement exactly");
      end Case_Replace;
   begin
      Case_Insert ("Beta", 0, "A", "ABeta", 1,
                   "Phase 415 insert at buffer start end-to-end");
      Case_Insert ("Alpha", 5, "!", "Alpha!", 6,
                   "Phase 415 insert at buffer end end-to-end");
      Case_Insert ("Alphabeta", 5, "123", "Alpha123beta", 8,
                   "Phase 415 multi-character insert at caret");
      Case_Insert ("AlphaBeta", 5, " ", "Alpha Beta", 6,
                   "Phase 415 space payload insert policy");
      Case_Insert ("AlphaBeta", 5, String'(1 => ASCII.HT),
                   "Alpha" & ASCII.HT & "Beta", 6,
                   "Phase 415 tab payload insert policy");
      Case_Insert ("AlphaBeta", 5, String'(1 => ASCII.LF),
                   "Alpha" & ASCII.LF & "Beta", 6,
                   "Phase 415 line-boundary payload insert policy");
      Case_Insert ("", 0, "A", "A", 1,
                   "Phase 415 empty buffer insert policy");

      Case_Replace ("Alpha", 0, 5, "Beta", "Beta", 4, "Alpha",
                    "Phase 415 select-all replacement");
      Case_Replace ("Alpha Beta", 6, 10, "Gamma", "Alpha Gamma", 11, "Beta",
                    "Phase 415 forward single-line replacement");
      Case_Replace ("Alpha Beta", 10, 6, "Gamma", "Alpha Gamma", 11, "Beta",
                    "Phase 415 backward single-line replacement equivalence");
      Case_Replace ("Alpha Beta", 5, 6, "_", "Alpha_Beta", 6, " ",
                    "Phase 415 whitespace replacement");
      Case_Replace ("Alpha.Beta", 5, 6, "!", "Alpha!Beta", 6, ".",
                    "Phase 415 punctuation replacement");
      Case_Replace ("Alpha" & ASCII.HT & "Beta", 5, 6, " ", "Alpha Beta", 6,
                    String'(1 => ASCII.HT),
                    "Phase 415 tab replacement");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 5, 6, " ", "Alpha Beta", 6,
                    String'(1 => ASCII.LF),
                    "Phase 415 line-boundary replacement");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 0, 11, "X", "X", 1,
                    "Alpha" & ASCII.LF & "Beta",
                    "Phase 415 cross-line select-all replacement");
   end Test_Phase415_Text_Insert_Workflow_Transform_And_Replacement;


   procedure Test_Phase415_Text_Insert_Noops_Redo_Dirty_And_Find


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("Alpha");
      S.Active_Replace_Text := To_Unbounded_String ("Omega");
      S.Active_Find_Stale := False;
      Set_Primary_Selection (S, 0, 5);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Execute_Text_Input (S, "");
      Assert_Buffer_Text (S, "Alpha", "Phase 415 empty payload must not delete selection");
      Assert (Editor.Selection.Has_Selection (S),
              "Phase 415 empty payload preserves valid selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 415 empty payload creates no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 415 empty payload creates no redo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 415 empty payload preserves dirty state");
      Assert (not S.Active_Find_Stale,
              "Phase 415 empty payload does not invalidate Find");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 415 empty payload leaves Clipboard text unchanged");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "Phase 415 empty payload records no Navigation History");

      Execute_Text_Input (S, String'(1 => ASCII.NUL));
      Assert_Buffer_Text (S, "Alpha", "Phase 415 NUL payload must not mutate text");
      Assert (Editor.Selection.Has_Selection (S),
              "Phase 415 NUL payload preserves selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 415 NUL payload creates no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 415 NUL payload preserves redo stack");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 415 NUL payload preserves dirty state");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 0
              and then S.Carets (S.Carets.First_Index).Pos = 5,
              "Phase 415 NUL payload preserves selection anchor/focus");
      Assert (not S.Active_Find_Stale,
              "Phase 415 NUL payload does not invalidate Find");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 415 NUL payload leaves Clipboard text unchanged");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "Phase 415 NUL payload records no Navigation History");

      Set_Caret (S, 5);
      Execute_Text_Input (S, "!");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha", "Phase 415 redo preservation setup undo restores clean text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 415 undo leaves redo available before no-op/failure");

      Execute_Text_Input (S, "");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 415 empty payload preserves redo stack after undo");
      Execute_Text_Input (S, String'(1 => ASCII.ESC));
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 415 invalid payload preserves redo stack after undo");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha!", "Phase 415 redo still restores prior edit after failed Text Insert");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Set_Primary_Selection (S, 0, 5);
      Execute_Text_Input (S, "Q");
      Assert_Buffer_Text (S, "Q", "Phase 415 successful replacement after undo applies new text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 415 successful replacement after undo clears redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Q", "Phase 415 redo after invalidation leaves replacement text unchanged");
   end Test_Phase415_Text_Insert_Noops_Redo_Dirty_And_Find;


   procedure Test_Phase415_Text_Insert_Clipboard_Navigation_Active_Buffer_And_Overlay_Workflow


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Cmd            : Editor.Commands.Command;
      A_Id           : Editor.Buffers.Buffer_Id;
      B_Id           : Editor.Buffers.Buffer_Id;
      Undo_Before    : Natural := 0;
      Redo_Before    : Natural := 0;
      Dirty_Before   : Boolean := False;
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, 5);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Execute_Text_Input (S, "X");
      Assert_Text_Insert_Coherent
        (S, "AlphaX", 6, 1, 0, True, To_Unbounded_String ("CLIP"),
         Before_Back, Before_Fwd,
         "Phase 415 Text Insert ignores Clipboard and Navigation History");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert_Buffer_Text
        (S, "AlphaXCLIP",
         "Phase 415 Paste still uses original Clipboard after Text Insert");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 415 Text Insert did not consume Clipboard before Paste");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 4);
      Execute_Text_Input (S, "!");
      Assert_Buffer_Text (S, "Beta!", "Phase 415 active buffer B receives Text Insert");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text (S, "AlphaXCLIP", "Phase 415 inactive buffer A retained its own text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "AlphaX", "Phase 415 undo in A affects only A");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text (S, "Beta!", "Phase 415 switch back to B preserves B inserted text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Beta", "Phase 415 undo in B affects only B");

      Editor.State.Load_Text (S, "Core");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 2);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Y';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Y'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('Y'));
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text (S, "CoYre", "Phase 415 editor focus text-entry routes to canonical insertion");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 415 Input_Bridge editor insertion creates canonical undo entry");

      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Quick_Open);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('Z'));
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text (S, "CoYre", "Phase 415 Quick Open field consumes text before editor buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 415 overlay input creates no buffer undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 415 overlay input preserves buffer redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "Phase 415 overlay input preserves dirty state");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase415_Text_Insert_Clipboard_Navigation_Active_Buffer_And_Overlay_Workflow;


   procedure Test_Phase415_Text_Insert_Mixed_Editing_Features_Render_And_Persistence


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Undo_Before   : Natural := 0;
      Redo_Before   : Natural := 0;
      Dirty_Before  : Boolean := False;
      Text_Before   : Unbounded_String;
      Back_Before   : Natural := 0;
      Fwd_Before    : Natural := 0;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta" & ASCII.LF & "Gamma");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 5);

      Execute_Text_Input (S, "X");
      Assert_Buffer_Text (S, "AlphaX Beta" & ASCII.LF & "Gamma",
                          "Phase 415 mixed workflow starts with Text Insert");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text (S, "Alpha Beta" & ASCII.LF & "Gamma",
                          "Phase 415 Character Delete consumes canonical post-insert text");
      Execute_Text_Input (S, "Y");
      Assert_Buffer_Text (S, "AlphaY Beta" & ASCII.LF & "Gamma",
                          "Phase 415 Text Insert works after Character Delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, " Beta" & ASCII.LF & "Gamma",
                          "Phase 415 Word Delete consumes canonical post-insert text");
      Execute_Text_Input (S, "Alpha");
      Assert_Buffer_Text (S, "Alpha Beta" & ASCII.LF & "Gamma",
                          "Phase 415 Text Insert works after Word Delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Execute_Text_Input (S, "T");
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "T Beta" & ASCII.LF & "Gamma",
                          "Phase 415 Text Insert works after Line Split");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Execute_Text_Input (S, "U");
      Assert (Index (To_Unbounded_String (Buffer_Text (S)), "U") > 0,
              "Phase 415 Text Insert works after Line Join");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Execute_Text_Input (S, "V");
      Assert (Index (To_Unbounded_String (Buffer_Text (S)), "V") > 0,
              "Phase 415 Text Insert works after Indentation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Execute_Text_Input (S, "W");
      Assert (Index (To_Unbounded_String (Buffer_Text (S)), "W") > 0,
              "Phase 415 Text Insert works after Line Comment toggle");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 415 mixed editing workflow leaves Clipboard owned by Clipboard commands only");

      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Text_Before := To_Unbounded_String (Buffer_Text (S));
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Fwd_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "Phase 415 render snapshot reflects current text length");
      Assert (To_Unbounded_String (Buffer_Text (S)) = Text_Before,
              "Phase 415 render snapshot must not mutate text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 415 render snapshot must not mutate undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 415 render snapshot must not mutate redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "Phase 415 render snapshot must not mutate dirty state");
      Assert_Navigation_Counts (S, Back_Before, Fwd_Before,
                                "Phase 415 render snapshot records no Navigation History");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "text insert") = 0
         and then Index (Summary, "last inserted text") = 0
         and then Index (Summary, "last inserted range") = 0
         and then Index (Summary, "last replacement range") = 0
         and then Index (Summary, "typed text history") = 0
         and then Index (Summary, "input payload history") = 0
         and then Index (Summary, "text-insert policy") = 0
         and then Index (Summary, "ime") = 0
         and then Index (Summary, "autocomplete") = 0
         and then Index (Summary, "snippet") = 0,
         "Phase 415 persistence excludes Text Insert transient/policy/history state");
   end Test_Phase415_Text_Insert_Mixed_Editing_Features_Render_And_Persistence;


   procedure Test_Phase415_Text_Insert_Overlay_Owner_Matrix_And_Command_Surface


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      procedure Bridge_Text
        (S  : in out Editor.State.State_Type;
         Ch : Character)
      is
         Cmd : Editor.Commands.Command;
      begin
         Cmd.Kind := Editor.Commands.Insert_Text_Input;
         Cmd.Ch := Ch;
         Cmd.Text := To_Unbounded_String (String'(1 => Ch));
         Cmd.Code := Wide_Wide_Character'Val (Character'Pos (Ch));
         Editor.Input_Bridge.Set_State_For_Test (S);
         Editor.Input_Bridge.Handle (Cmd);
         S := Editor.Input_Bridge.Get_State_For_Test;
      end Bridge_Text;

      procedure Assert_Non_Goal_Command_Absent (Name : String) is
         Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
         Found    : Boolean := False;
      begin
         Resolved := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found and then Resolved = Editor.Commands.No_Command,
                 "Phase 415 non-goal command exposed: " & Name);
      end Assert_Non_Goal_Command_Absent;

      S             : Editor.State.State_Type;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Desc          : Editor.Commands.Command_Descriptor;
      Undo_Before   : Natural := 0;
      Redo_Before   : Natural := 0;
      Dirty_Before  : Boolean := False;
      Back_Before   : Natural := 0;
      Fwd_Before    : Natural := 0;
   begin
      --  Arbitrary parameterized text insertion remains an internal/editor
      --  text-entry route, not a public command-palette/keybinding surface.
      Desc := Editor.Commands.Descriptor (Editor.Commands.Command_Insert_Newline);
      Assert (Desc.Visibility = Editor.Commands.Hidden_Command,
              "Phase 415 newline text input command remains hidden from the palette");
      Assert_Non_Goal_Command_Absent ("edit.text.insert-snippet");
      Assert_Non_Goal_Command_Absent ("edit.text.insert-template");
      Assert_Non_Goal_Command_Absent ("edit.text.insert-pair");
      Assert_Non_Goal_Command_Absent ("edit.text.insert-autocomplete");
      Assert_Non_Goal_Command_Absent ("edit.text.insert-from-lsp");
      Assert_Non_Goal_Command_Absent ("edit.text.insert-formatted");
      Assert_Non_Goal_Command_Absent ("edit.multi-cursor.insert");
      Assert_Non_Goal_Command_Absent ("edit.selection.replace-with-template");
      Assert_Non_Goal_Command_Absent ("edit.insert.smart-newline");
      Assert_Non_Goal_Command_Absent ("edit.insert.auto-indent");
      Assert_Non_Goal_Command_Absent ("edit.insert.ime-compose");

      --  Explicit command-style newline input is still the canonical Text
      --  Insert route: it is not Line Split and it produces the Text Insert
      --  primary message only.
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 5);
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Fwd_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Insert_Newline);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "Phase 415 explicit newline route inserts canonical line boundary");
      Assert (Message_Text (S) = "Inserted text",
              "Phase 415 explicit newline route reports Text Insert only");
      Assert (Message_Text (S) /= "Split line",
              "Phase 415 newline route must not report Line Split participation");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 415 explicit newline creates exactly one undo entry");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 415 explicit newline does not touch Clipboard");
      Assert_Navigation_Counts
        (S, Back_Before, Fwd_Before,
         "Phase 415 explicit newline records no Navigation History");

      --  Go To Line prompt owns printable input before the editor buffer.
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 0);
      Editor.Input_Bridge.Reset;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Goto_Line);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Bridge_Text (S, '3');
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert_Buffer_Text
        (S, "Alpha",
         "Phase 415 Go To Line prompt consumes text before buffer insertion");
      Assert (Snap.Goto_Line_Visible
              and then To_String (Snap.Goto_Line_Query) = "3",
              "Phase 415 Go To Line query receives overlay text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 415 Go To Line input creates no buffer undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 415 Go To Line input preserves buffer redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "Phase 415 Go To Line input preserves buffer dirty state");

      --  Find prompt owns printable input before the editor buffer.
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Alpha");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 6);
      Editor.Input_Bridge.Reset;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Find_Show);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Bridge_Text (S, 'B');
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert_Buffer_Text
        (S, "Alpha Beta Alpha",
         "Phase 415 Find prompt consumes text before buffer insertion");
      Assert (Snap.Find_Visible and then To_String (Snap.Find_Query) = "B",
              "Phase 415 Find query receives overlay text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 415 Find prompt input creates no buffer undo entry");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "Phase 415 Find prompt input preserves dirty state");

      --  Replace prompt state is independent from Text Insert.  Text Insert
      --  may stale Find ranges through the canonical edit hook, but it must
      --  not rewrite the replacement text or prompt state.
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run Run");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 3);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Execute_Text_Input (S, "!");
      Assert_Buffer_Text
        (S, "Run! Run",
         "Phase 415 Text Insert mutates only buffer text under Replace state");
      Assert (S.Active_Replace_Prompt
              and then To_String (S.Active_Replace_Text) = "Execute",
              "Phase 415 Text Insert preserves Replace prompt text/state");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Run"),
              "Phase 415 Text Insert preserves Find query while invalidating ranges");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Phase 415 Text Insert invalidates Find ranges through edit hook only");
   end Test_Phase415_Text_Insert_Overlay_Owner_Matrix_And_Command_Surface;








   procedure Test_Phase416_Text_Insert_Canonical_Route_State_And_Persistence








     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Cmd         : Editor.Commands.Command;
      Workspace   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary     : Unbounded_String;
      Back_Before : Natural := 0;
      Fwd_Before  : Natural := 0;
      Undo_Before : Natural := 0;
      Dirty_Before: Boolean := False;
   begin
      Editor.Input_Bridge.Reset;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Replace_Text := To_Unbounded_String ("Gamma");
      S.Active_Find_Stale := False;
      Set_Primary_Selection (S, 6, 10);
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Fwd_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Execute_Text_Input (S, "Delta");

      Assert_Buffer_Text
        (S, "Alpha Delta",
         "Phase 416 canonical Text Insert replacement mutates active buffer only once");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 416 replacement remains one canonical undoable edit");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 416 replacement creates no redo entry");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 416 replacement uses canonical dirty policy");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Phase 416 Text Insert does not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Gamma"),
              "Phase 416 Text Insert does not mutate Replace text");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Phase 416 Text Insert invalidates Find through canonical hook");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 416 Text Insert never reads or mutates Clipboard text");
      Assert_Navigation_Counts
        (S, Back_Before, Fwd_Before,
         "Phase 416 Text Insert records no Navigation History");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "text insert") = 0
         and then Index (Summary, "last inserted text") = 0
         and then Index (Summary, "last inserted range") = 0
         and then Index (Summary, "last replacement range") = 0
         and then Index (Summary, "text insert command history") = 0
         and then Index (Summary, "text insert caret") = 0
         and then Index (Summary, "text insert availability") = 0
         and then Index (Summary, "text-insert policy") = 0
         and then Index (Summary, "typed text history") = 0
         and then Index (Summary, "input payload history") = 0
         and then Index (Summary, "internal text-entry event") = 0
         and then Index (Summary, "overlay-routed editor text") = 0
         and then Index (Summary, "snippet") = 0
         and then Index (Summary, "autocomplete") = 0
         and then Index (Summary, "ime") = 0
         and then Index (Summary, "formatting insertion") = 0
         and then Index (Summary, "clipboard mirror") = 0,
         "Phase 416 persistence excludes canonical and removed Text Insert transient state");

      --  Overlay focus remains a hard gate before the canonical active-buffer
      --  insertion route.  The focused Quick Open field receives text, while
      --  active-buffer text/undo/dirty state are unchanged.
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Buffer");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 0);
      Editor.Input_Bridge.Reset;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Open_Quick_Open);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Q';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Q'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('Q'));
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;

      Assert_Buffer_Text
        (S, "Buffer",
         "Phase 416 overlay text-entry must not leak into active-buffer insertion");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 416 overlay text-entry creates no active-buffer undo entry");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "Phase 416 overlay text-entry preserves active-buffer dirty state");
   end Test_Phase416_Text_Insert_Canonical_Route_State_And_Persistence;


   procedure Test_Phase416_Text_Insert_Behavior_Preservation_Smoke


     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AB");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 1);

      Execute_Text_Input (S, " " & ASCII.HT & ".");
      Assert_Buffer_Text
        (S, "A " & ASCII.HT & ".B",
         "Phase 416 accepted whitespace/tab/punctuation payload inserts exactly");
      Assert (S.Carets (S.Carets.First_Index).Pos = 4,
              "Phase 416 insert-at-caret moves caret to payload end");

      Set_Primary_Selection (S, 4, 1);
      Execute_Text_Input (S, "X" & ASCII.LF & "Y");
      Assert_Buffer_Text
        (S, "AX" & ASCII.LF & "YB",
         "Phase 416 backward replacement keeps canonical line-boundary payload policy");
      Assert (S.Carets (S.Carets.First_Index).Pos = 4,
              "Phase 416 replacement moves caret to payload end");
      Assert (not Editor.Selection.Has_Selection (S),
              "Phase 416 replacement clears active selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 2,
              "Phase 416 insert plus replacement are two canonical undo entries");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "A " & ASCII.HT & ".B",
         "Phase 416 undo restores replacement Before_Text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "AX" & ASCII.LF & "YB",
         "Phase 416 redo restores replacement After_Text without replaying Text Insert");

      Execute_Text_Input (S, "");
      Assert_Buffer_Text
        (S, "AX" & ASCII.LF & "YB",
         "Phase 416 empty payload remains a non-mutating no-op");
      Execute_Text_Input (S, String'(1 => ASCII.CR));
      Assert_Buffer_Text
        (S, "AX" & ASCII.LF & "YB",
         "Phase 416 invalid payload remains non-mutating");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 416 behavior smoke preserves Clipboard boundary");
   end Test_Phase416_Text_Insert_Behavior_Preservation_Smoke;



   procedure Test_Phase540_Trim_Trailing_Whitespace_Command_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Trim_Trailing_Whitespace) =
         "edit.trim-trailing-whitespace",
         "trim trailing whitespace stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Trim_Trailing_Whitespace).Category =
         Editor.Commands.Edit_Category,
         "trim trailing whitespace must be an Edit command");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Trim_Trailing_Whitespace),
         "trim trailing whitespace must be bindable");
      Assert
        (Editor.Commands.Is_Text_Editing_Command
           (Editor.Commands.Command_Trim_Trailing_Whitespace),
         "trim trailing whitespace must be classified as text editing");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.trim-trailing-whitespace", Found);
      Assert (Found, "trim trailing whitespace stable name must resolve");
      Assert
        (Id = Editor.Commands.Command_Trim_Trailing_Whitespace,
         "trim trailing whitespace stable name resolves wrong command");
   end Test_Phase540_Trim_Trailing_Whitespace_Command_Surface;

   procedure Test_Phase540_Expected_Command_Names_Resolve
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Assert_Resolves
        (Name     : String;
         Expected : Editor.Commands.Command_Id)
      is
         Found : Boolean := False;
         Id    : constant Editor.Commands.Command_Id :=
           Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      begin
         Assert (Found, "Phase 540 expected command name did not resolve: " & Name);
         Assert
           (Id = Expected,
            "Phase 540 expected command name resolved to wrong command: " & Name);
      end Assert_Resolves;
   begin
      Assert_Resolves ("cursor.word-left", Editor.Commands.Command_Move_Word_Left);
      Assert_Resolves ("cursor.word-right", Editor.Commands.Command_Move_Word_Right);
      Assert_Resolves ("selection.extend-left", Editor.Commands.Command_Select_Left);
      Assert_Resolves ("selection.extend-right", Editor.Commands.Command_Select_Right);
      Assert_Resolves ("selection.extend-up", Editor.Commands.Command_Select_Up);
      Assert_Resolves ("selection.extend-down", Editor.Commands.Command_Select_Down);
      Assert_Resolves ("selection.extend-word-left", Editor.Commands.Command_Select_Word_Left);
      Assert_Resolves ("selection.extend-word-right", Editor.Commands.Command_Select_Word_Right);
      Assert_Resolves ("selection.extend-line-start", Editor.Commands.Command_Select_Line_Start);
      Assert_Resolves ("selection.extend-line-end", Editor.Commands.Command_Select_Line_End);
      Assert_Resolves ("selection.extend-buffer-start", Editor.Commands.Command_Select_Document_Start);
      Assert_Resolves ("selection.extend-buffer-end", Editor.Commands.Command_Select_Document_End);
      Assert_Resolves ("selection.select-word", Editor.Commands.Command_Select_Word);
      Assert_Resolves ("selection.select-line", Editor.Commands.Command_Select_Line);
      Assert_Resolves ("selection.select-all", Editor.Commands.Command_Select_All);
      Assert_Resolves ("selection.clear", Editor.Commands.Command_Selection_Clear);
      Assert_Resolves ("selection.delete", Editor.Commands.Command_Selection_Delete);
      Assert_Resolves ("selection.expand-to-line", Editor.Commands.Command_Select_Line);
      Assert_Resolves ("edit.delete-word-backward", Editor.Commands.Command_Word_Delete_Previous);
      Assert_Resolves ("edit.delete-word-forward", Editor.Commands.Command_Word_Delete_Next);
      Assert_Resolves ("edit.duplicate-line", Editor.Commands.Command_Line_Duplicate);
      Assert_Resolves ("edit.move-line-up", Editor.Commands.Command_Line_Move_Up);
      Assert_Resolves ("edit.move-line-down", Editor.Commands.Command_Line_Move_Down);
      Assert_Resolves ("edit.join-lines", Editor.Commands.Command_Line_Join_Next);
      Assert_Resolves ("edit.split-line", Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Resolves ("edit.trim-trailing-whitespace", Editor.Commands.Command_Trim_Trailing_Whitespace);
   end Test_Phase540_Expected_Command_Names_Resolve;

   procedure Test_Phase540_Trim_Trailing_Whitespace_Edit_Group
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "alpha  " & ASCII.LF & "be" & ASCII.HT & ASCII.HT & ASCII.LF & "ta");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 3);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Trim_Trailing_Whitespace);

      Assert_Buffer_Text
        (S, "alpha" & ASCII.LF & "be" & ASCII.LF & "ta",
         "Phase 540 trim must remove only line-end spaces and tabs");
      Assert (Message_Text (S) = "Trimmed trailing whitespace",
              "Phase 540 trim message mismatch");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 540 trim must dirty the active buffer when text changes");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 540 trim must create one grouped undo step");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 540 trim must not create redo entries");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "alpha  " & ASCII.LF & "be" & ASCII.HT & ASCII.HT & ASCII.LF & "ta",
         "Phase 540 trim undo must restore original whitespace");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "alpha" & ASCII.LF & "be" & ASCII.LF & "ta",
         "Phase 540 trim redo must reapply grouped trim");
   end Test_Phase540_Trim_Trailing_Whitespace_Edit_Group;

   procedure Test_Phase540_Trim_Trailing_Whitespace_Noop_Is_Nonmutating
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 2);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Trim_Trailing_Whitespace);

      Assert_Buffer_Text
        (S, "alpha" & ASCII.LF & "beta",
         "Phase 540 trim no-op must preserve text");
      Assert (Message_Text (S) = "No trailing whitespace",
              "Phase 540 trim unavailable/no-op message mismatch");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 540 trim no-op must not dirty the buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 540 trim no-op must not create an undo entry");
   end Test_Phase540_Trim_Trailing_Whitespace_Noop_Is_Nonmutating;


   procedure Test_Phase540_Trim_Trailing_Whitespace_Selected_Lines_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one  " & ASCII.LF & "two  " & ASCII.LF & "three" & ASCII.HT);
      Editor.State.Set_Dirty (S, False);

      --  Select only the second logical line.  The command must not treat
      --  this as a project/global cleanup or trim unrelated buffer lines.
      Set_Primary_Selection (S, 7, 10);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Trim_Trailing_Whitespace);

      Assert_Buffer_Text
        (S, "one  " & ASCII.LF & "two" & ASCII.LF & "three" & ASCII.HT,
         "Phase 540 selected-line trim must leave unselected trailing whitespace intact");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 540 selected-line trim must dirty when text changes");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 540 selected-line trim must create one grouped undo step");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "one  " & ASCII.LF & "two  " & ASCII.LF & "three" & ASCII.HT,
         "Phase 540 selected-line trim undo must restore only the grouped trim");
   end Test_Phase540_Trim_Trailing_Whitespace_Selected_Lines_Only;

   procedure Test_Phase540_Selected_Line_Trim_Noop_Does_Not_Clean_Other_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one  " & ASCII.LF & "two" & ASCII.LF & "three  ");
      Editor.State.Set_Dirty (S, False);

      --  Select the clean second logical line.  The selected-line policy must
      --  not fall back to whole-buffer trimming merely because the selected
      --  line itself has nothing to remove.
      Set_Primary_Selection (S, 6, 9);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Trim_Trailing_Whitespace);

      Assert_Buffer_Text
        (S, "one  " & ASCII.LF & "two" & ASCII.LF & "three  ",
         "Phase 540 selected clean line trim must not trim unselected lines");
      Assert (Message_Text (S) = "No trailing whitespace",
              "Phase 540 selected clean line trim unavailable/no-op message mismatch");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 540 selected clean line trim no-op must not dirty");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 540 selected clean line trim no-op must not create undo");
   end Test_Phase540_Selected_Line_Trim_Noop_Does_Not_Clean_Other_Lines;


   procedure Test_Phase540_Trim_Availability_Is_Precise_And_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 2);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Trim_Trailing_Whitespace);

      Assert
        (A.Status = Editor.Commands.Command_Unavailable,
         "Phase 540 clean-buffer trim availability must be unavailable");
      Assert
        (Editor.Commands.Unavailable_Reason (A) = "No trailing whitespace",
         "Phase 540 clean-buffer trim availability reason mismatch");
      Assert_Buffer_Text
        (S, "alpha" & ASCII.LF & "beta",
         "Phase 540 trim availability must not mutate text");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 540 trim availability must not dirty the buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 540 trim availability must not create undo history");
   end Test_Phase540_Trim_Availability_Is_Precise_And_Side_Effect_Free;

   procedure Test_Phase540_Selected_Trim_Availability_Uses_Selected_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one  " & ASCII.LF & "two" & ASCII.LF & "three  ");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Selection (S, 6, 9);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Trim_Trailing_Whitespace);

      Assert
        (A.Status = Editor.Commands.Command_Unavailable,
         "Phase 540 selected clean line trim availability must be unavailable");
      Assert
        (Editor.Commands.Unavailable_Reason (A) = "No trailing whitespace",
         "Phase 540 selected clean line trim availability reason mismatch");
      Assert_Buffer_Text
        (S, "one  " & ASCII.LF & "two" & ASCII.LF & "three  ",
         "Phase 540 selected-line trim availability must not trim other lines");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 540 selected-line trim availability must not dirty");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "Phase 540 selected-line trim availability must not create undo");
   end Test_Phase540_Selected_Trim_Availability_Uses_Selected_Lines;



   procedure Test_Phase388_Command_Palette_Projects_Canonical_Indentation_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Phase385_Indent_Command_Descriptors (T);
   end Test_Phase388_Command_Palette_Projects_Canonical_Indentation_Only;

   procedure Test_Phase388_Keybindings_Reject_Removed_Name_Indentation_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Phase385_Indent_Input_Bridge_And_Availability_Side_Effects (T);
   end Test_Phase388_Keybindings_Reject_Removed_Name_Indentation_Names;

   procedure Test_Phase388_Canonical_Indentation_Path_And_Persistence_Exclusion
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Phase387_Indent_Increase_Workflow_Matrix (T);
   end Test_Phase388_Canonical_Indentation_Path_And_Persistence_Exclusion;

   procedure Test_Phase392_Keybindings_Reject_Removed_Name_Line_Comment_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Phase392_Canonical_Line_Comment_Path_And_Persistence_Exclusion (T);
   end Test_Phase392_Keybindings_Reject_Removed_Name_Line_Comment_Names;

   procedure Test_Phase396_Line_Join_Canonical_Cleanup_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Phase396_Line_Join_Canonical_Behavior_And_Persistence (T);
   end Test_Phase396_Line_Join_Canonical_Cleanup_Surface;

   procedure Test_Phase400_Line_Split_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Phase400_Line_Split_Canonical_Behavior_And_State_Boundaries (T);
   end Test_Phase400_Line_Split_Canonical_Surface_Cleanup;

   procedure Test_Phase408_Character_Delete_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Phase408_Character_Delete_Canonical_Routes_State_And_Persistence (T);
   end Test_Phase408_Character_Delete_Canonical_Surface_Cleanup;

   procedure Test_Phase412_Selection_Delete_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Phase412_Selection_Delete_Canonical_State_Only_Workflow (T);
   end Test_Phase412_Selection_Delete_Canonical_Surface_Cleanup;

   overriding procedure Register_Tests (T : in out Line_Edit_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase540_Trim_Trailing_Whitespace_Command_Surface'Access,
         "Phase 540 Trim Trailing Whitespace Command Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase540_Expected_Command_Names_Resolve'Access,
         "Phase 540 Expected Command Names Resolve");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase540_Trim_Trailing_Whitespace_Edit_Group'Access,
         "Phase 540 Trim Trailing Whitespace Edit Group");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase540_Trim_Trailing_Whitespace_Noop_Is_Nonmutating'Access,
         "Phase 540 Trim Trailing Whitespace Noop Is Nonmutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase540_Trim_Trailing_Whitespace_Selected_Lines_Only'Access,
         "Phase 540 Trim Trailing Whitespace Selected Lines Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase540_Selected_Line_Trim_Noop_Does_Not_Clean_Other_Lines'Access,
         "Phase 540 Selected Line Trim Noop Does Not Clean Other Lines");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase540_Trim_Availability_Is_Precise_And_Side_Effect_Free'Access,
         "Phase 540 Trim Availability Is Precise And Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase540_Selected_Trim_Availability_Uses_Selected_Lines'Access,
         "Phase 540 Selected Trim Availability Uses Selected Lines");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Command_Descriptors'Access,
         "Phase 381 Line Edit Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Delete_Current_Line_Undo_Redo'Access,
         "Phase 381 Delete Current Line Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Duplicate_Current_Line'Access,
         "Phase 381 Duplicate Current Line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Move_Line_Up_Down_And_Boundaries'Access,
         "Phase 381 Move Line Up Down Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Empty_Buffer_No_Ops'Access,
         "Phase 381 Empty Buffer No Ops");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Delete_First_Last_And_One_Line'Access,
         "Phase 381 Delete First Last And One Line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Duplicate_Last_Line_Undo_Redo'Access,
         "Phase 381 Duplicate Last Line Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Last_Line_Move_Down_No_Op_Preserves_Redo_Dirty'Access,
         "Phase 381 Last Line Move Down No Op Preserves Redo Dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Clipboard_Selection_Navigation_Boundaries'Access,
         "Phase 381 Clipboard Selection Navigation Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Input_Bridge_Routes_Line_Commands'Access,
         "Phase 381 Input Bridge Routes Line Commands");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Availability_Has_No_Side_Effects'Access,
         "Phase 381 Availability Has No Side Effects");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase381_Trailing_Newline_Line_Boundaries'Access,
         "Phase 381 Trailing Newline Line Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase382_Delete_Blank_Whitespace_And_EOF_Lines'Access,
         "Phase 382 Delete Blank Whitespace And EOF Lines");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase382_Duplicate_Whitespace_And_Caret_Clamp'Access,
         "Phase 382 Duplicate Whitespace And Caret Clamp");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase382_Move_Blank_Line_And_Attached_Caret'Access,
         "Phase 382 Move Blank Line And Attached Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase382_Redo_Find_And_Boundary_No_Op_Reliability'Access,
         "Phase 382 Redo Find And Boundary No Op Reliability");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase383_Delete_Duplicate_Move_Workflow_Consistency'Access,
         "Phase 383 Delete Duplicate Move Workflow Consistency");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase383_Line_Terminator_Matrix_Undo_Redo'Access,
         "Phase 383 Line Terminator Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase383_Selection_Clipboard_Find_Redo_Boundaries'Access,
         "Phase 383 Selection Clipboard Find Redo Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase383_Dirty_History_Clear_And_No_Op_Policy'Access,
         "Phase 383 Dirty History Clear And No Op Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase383_Availability_Projection_And_Non_Goal_Surface'Access,
         "Phase 383 Availability Projection And Non Goal Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase384_Keybinding_Config_Rejects_Removed_Name_Line_Names'Access,
         "Phase 384 Keybinding Config Rejects Removed_Name Line Names");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase384_Default_Keybindings_And_Runtime_Routes_Are_Canonical'Access,
         "Phase 384 Default Keybindings And Runtime Routes Are Canonical");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase385_Indent_Command_Descriptors'Access,
         "Phase 385 Indent Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase385_Indent_Increase_Undo_Redo_And_Caret'Access,
         "Phase 385 Indent Increase Undo Redo And Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase385_Indent_Increase_Blank_Whitespace_And_Empty_Buffer'Access,
         "Phase 385 Indent Increase Blank Whitespace And Empty Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase385_Outdent_Policy_Undo_Redo_And_No_Op'Access,
         "Phase 385 Outdent Policy Undo Redo And No Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase385_Indent_Selection_Clipboard_Find_And_Navigation_Boundaries'Access,
         "Phase 385 Indent Selection Clipboard Find And Navigation Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase385_Indent_Input_Bridge_And_Availability_Side_Effects'Access,
         "Phase 385 Indent Input Bridge And Availability Side Effects");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase386_Leading_Whitespace_Outdent_Matrix'Access,
         "Phase 386 Leading Whitespace Outdent Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase386_Indent_Exact_Unit_And_Line_Boundaries'Access,
         "Phase 386 Indent Exact Unit And Line Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase386_Redo_Find_Selection_Clipboard_And_Navigation_Reliability'Access,
         "Phase 386 Redo Find Selection Clipboard And Navigation Reliability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase386_Line_Edit_Coexistence_And_Current_Line_Only'Access,
         "Phase 386 Line Edit Coexistence And Current Line Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase386_No_Caret_Render_Persistence_And_Non_Goals'Access,
         "Phase 386 No Caret Render Persistence And Non Goals");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase387_Indent_Increase_Workflow_Matrix'Access,
         "Phase 387 Indent Increase Workflow Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase387_Outdent_Workflow_And_Whitespace_Matrix'Access,
         "Phase 387 Outdent Workflow And Whitespace Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase387_Selection_Clipboard_Line_Edit_Integration'Access,
         "Phase 387 Selection Clipboard Line Edit Integration");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase387_Render_Availability_And_Persistence_Are_Read_Only'Access,
         "Phase 387 Render Availability And Persistence Are Read Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase388_Command_Palette_Projects_Canonical_Indentation_Only'Access,
         "Phase 388 Command Palette Projects Canonical Indentation Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase388_Keybindings_Reject_Removed_Name_Indentation_Names'Access,
         "Phase 388 Keybindings Reject Removed_Name Indentation Names");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase388_Canonical_Indentation_Path_And_Persistence_Exclusion'Access,
         "Phase 388 Canonical Indentation Path And Persistence Exclusion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase389_Line_Comment_Command_Descriptors'Access,
         "Phase 389 Line Comment Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase389_Comment_Line_Prefix_Matrix_Undo_Redo'Access,
         "Phase 389 Comment Line Prefix Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase389_Uncomment_And_Toggle_Policies'Access,
         "Phase 389 Uncomment And Toggle Policies");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase389_No_Op_Redo_Empty_And_Active_Buffer_Isolation'Access,
         "Phase 389 No Op Redo Empty And Active Buffer Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase389_Indentation_And_Line_Editing_Coexistence'Access,
         "Phase 389 Indentation And Line Editing Coexistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase389_Line_Comment_Edge_Matrix_And_Redo_Preservation'Access,
         "Phase 389 Line Comment Edge Matrix And Redo Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase389_Boundaries_Availability_And_Persistence'Access,
         "Phase 389 Boundaries Availability And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase390_Prefix_Matrix_And_Current_Line_Only'Access,
         "Phase 390 Prefix Matrix And Current Line Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase390_Caret_Selection_Find_Clipboard_Navigation'Access,
         "Phase 390 Caret Selection Find Clipboard Navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase390_Redo_Dirty_And_No_Op_Policy'Access,
         "Phase 390 Redo Dirty And No Op Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase390_Indentation_Line_Edit_And_Toggle_Sharing'Access,
         "Phase 390 Indentation Line Edit And Toggle Sharing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase390_Completeness_Toggle_No_Op_Find_And_Persistence'Access,
         "Phase 390 Completeness Toggle No Op Find And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase390_Completeness_Read_Only_Routes_And_No_Active_Buffer'Access,
         "Phase 390 Completeness Read Only Routes And No Active Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase390_Completeness_Line_Boundaries_And_No_Caret'Access,
         "Phase 390 Completeness Line Boundaries And No Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase390_Completeness_Active_Buffer_Isolation'Access,
         "Phase 390 Completeness Active Buffer Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase391_Line_Comment_Workflow_Matrices'Access,
         "Phase 391 Line Comment Workflow Matrices");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase391_Line_Boundaries_Caret_Selection_And_Find'Access,
         "Phase 391 Line Boundaries Caret Selection And Find");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase391_Indent_Line_Edit_Clipboard_And_Redo_Integration'Access,
         "Phase 391 Indent Line Edit Clipboard And Redo Integration");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase391_Read_Only_Routes_Feature_Independence_And_Persistence'Access,
         "Phase 391 Read Only Routes Feature Independence And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase392_Keybindings_Reject_Removed_Name_Line_Comment_Names'Access,
         "Phase 392 Keybindings Reject Removed_Name Line Comment Names");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase392_Canonical_Line_Comment_Path_And_Persistence_Exclusion'Access,
         "Phase 392 Canonical Line Comment Path And Persistence Exclusion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase393_Line_Join_Command_Descriptors'Access,
         "Phase 393 Line Join Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase393_Join_Next_Separator_Matrix_Undo_Redo'Access,
         "Phase 393 Join Next Separator Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase393_Join_Next_Boundaries_Redo_And_Caret'Access,
         "Phase 393 Join Next Boundaries Redo And Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase393_Join_Next_Boundaries_Selection_Find_Clipboard_Navigation'Access,
         "Phase 393 Join Next Boundaries Selection Find Clipboard Navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase393_Join_Next_Coexists_With_Line_Edit_Indent_And_Comment'Access,
         "Phase 393 Join Next Coexists With Line Edit Indent And Comment");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase393_Join_Next_Does_Not_Add_Forbidden_Aliases_Or_State'Access,
         "Phase 393 Join Next Does Not Add Forbidden Aliases Or State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase393_Join_Next_Input_Bridge_Route'Access,
         "Phase 393 Join Next Input Bridge Route");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase394_Join_Next_Separator_And_Boundary_Reliability'Access,
         "Phase 394 Join Next Separator And Boundary Reliability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase394_Join_Next_No_Op_Redo_Dirty_And_Find_Policy'Access,
         "Phase 394 Join Next No Op Redo Dirty And Find Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase394_Join_Next_Caret_Selection_Clipboard_Navigation_And_Render'Access,
         "Phase 394 Join Next Caret Selection Clipboard Navigation And Render");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase394_Join_Next_Mixed_Current_Line_Command_Workflows'Access,
         "Phase 394 Join Next Mixed Current Line Command Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase395_Join_Next_End_To_End_And_Separator_Workflows'Access,
         "Phase 395 Join Next End To End And Separator Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase395_Join_Next_Caret_Selection_Find_Clipboard_And_Render_Workflow'Access,
         "Phase 395 Join Next Caret Selection Find Clipboard And Render Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase395_Join_Next_Redo_Dirty_And_Mixed_Command_Coexistence'Access,
         "Phase 395 Join Next Redo Dirty And Mixed Command Coexistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase395_Join_Next_Active_Buffer_Routes_Features_And_Persistence'Access,
         "Phase 395 Join Next Active Buffer Routes Features And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase396_Line_Join_Canonical_Cleanup_Surface'Access,
         "Phase 396 Line Join Canonical Cleanup Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase396_Line_Join_Canonical_Behavior_And_Persistence'Access,
         "Phase 396 Line Join Canonical Behavior And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase397_Line_Split_Command_Descriptors_And_Routes'Access,
         "Phase 397 Line Split Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase397_Line_Split_Boundary_Matrix_Undo_Redo'Access,
         "Phase 397 Line Split Boundary Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase397_Line_Split_State_Boundaries_And_Persistence'Access,
         "Phase 397 Line Split State Boundaries And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase397_Completeness_No_Op_Redo_And_Boundaries'Access,
         "Phase 397 Completeness No Op Redo And Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase398_Line_Split_Exact_Position_Matrix'Access,
         "Phase 398 Line Split Exact Position Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase398_Line_Split_Selection_Find_Clipboard_Navigation_And_Render'Access,
         "Phase 398 Line Split Selection Find Clipboard Navigation And Render");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase398_Line_Split_Mixed_Current_Line_Command_Workflows'Access,
         "Phase 398 Line Split Mixed Current Line Command Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase398_Line_Split_Active_Buffer_And_Persistence_Boundaries'Access,
         "Phase 398 Line Split Active Buffer And Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase399_Line_Split_Workflow_Position_And_Boundary_Matrices'Access,
         "Phase 399 Line Split Workflow Position And Boundary Matrices");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase399_Line_Split_Undo_Redo_Dirty_Find_Clipboard_Navigation_Render'Access,
         "Phase 399 Line Split Undo Redo Dirty Find Clipboard Navigation Render");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase399_Line_Split_Mixed_Command_Coexistence_Workflows'Access,
         "Phase 399 Line Split Mixed Command Coexistence Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase399_Line_Split_Active_Buffer_Routes_Features_And_Persistence'Access,
         "Phase 399 Line Split Active Buffer Routes Features And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase399_Completeness_Selection_Caret_Only_And_Followups'Access,
         "Phase 399 Completeness Selection Caret Only And Followups");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase399_Completeness_No_Buffer_No_Caret_And_Routed_Input'Access,
         "Phase 399 Completeness No Buffer No Caret And Routed Input");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase399_Completeness_Read_Only_And_Persistence_Surfaces'Access,
         "Phase 399 Completeness Read Only And Persistence Surfaces");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase400_Line_Split_Canonical_Surface_Cleanup'Access,
         "Phase 400 Line Split Canonical Surface Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase400_Line_Split_Canonical_Behavior_And_State_Boundaries'Access,
         "Phase 400 Line Split Canonical Behavior And State Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase400_Line_Split_Failure_Read_Only_And_Ordinary_Newline_Separation'Access,
         "Phase 400 Line Split Failure Read Only And Ordinary Newline Separation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase401_Word_Delete_Command_Descriptors_And_Routes'Access,
         "Phase 401 Word Delete Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase401_Delete_Previous_Word_Boundaries_Selection_And_Undo'Access,
         "Phase 401 Delete Previous Word Boundaries Selection And Undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase401_Delete_Next_Word_Boundaries_No_Ops_And_Persistence'Access,
         "Phase 401 Delete Next Word Boundaries No Ops And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase402_Delete_Previous_Word_Reliability_Matrix'Access,
         "Phase 402 Delete Previous Word Reliability Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase402_Delete_Next_Word_Reliability_Matrix'Access,
         "Phase 402 Delete Next Word Reliability Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase402_Word_Delete_State_Integration_And_Read_Only_Boundaries'Access,
         "Phase 402 Word Delete State Integration And Read Only Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase402_Word_Delete_Current_Line_Coexistence_And_Persistence'Access,
         "Phase 402 Word Delete Current Line Coexistence And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase403_Word_Delete_Boundary_Transform_Workflows'Access,
         "Phase 403 Word Delete Boundary Transform Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase403_Word_Delete_Cross_Line_Selection_Find_Clipboard'Access,
         "Phase 403 Word Delete Cross Line Selection Find Clipboard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase403_Word_Delete_Undo_Redo_Dirty_And_Current_Line_Coexistence'Access,
         "Phase 403 Word Delete Undo Redo Dirty And Current Line Coexistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase403_Word_Delete_Active_Buffer_Routes_Features_And_Persistence'Access,
         "Phase 403 Word Delete Active Buffer Routes Features And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase404_Word_Delete_Canonical_Surface_Cleanup'Access,
         "Phase 404 Word Delete Canonical Surface Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase404_Word_Delete_Canonical_Routes_And_State_Boundaries'Access,
         "Phase 404 Word Delete Canonical Routes And State Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase404_Word_Delete_Behavior_Preservation_Smoke'Access,
         "Phase 404 Word Delete Behavior Preservation Smoke");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase405_Character_Delete_Command_Descriptors_And_Routes'Access,
         "Phase 405 Character Delete Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase405_Delete_Previous_Character_Boundaries_Selection_And_Undo'Access,
         "Phase 405 Delete Previous Character Boundaries Selection And Undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase405_Delete_Next_Character_Boundaries_No_Ops_And_State'Access,
         "Phase 405 Delete Next Character Boundaries No Ops And State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase405_Character_Delete_Completeness_Routes_State_And_Persistence'Access,
         "Phase 405 Character Delete Completeness Routes State And Persistence");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase406_Character_Delete_Previous_Reliability_Matrix'Access,
         "Phase 406 Character Delete Previous Reliability Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase406_Character_Delete_Next_Reliability_Matrix'Access,
         "Phase 406 Character Delete Next Reliability Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase406_Character_Delete_State_Integration_And_Read_Only_Boundaries'Access,
         "Phase 406 Character Delete State Integration And Read Only Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase406_Character_Delete_Mixed_Command_Coexistence_And_Persistence'Access,
         "Phase 406 Character Delete Mixed Command Coexistence And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase407_Character_Delete_Boundary_Transform_Workflows'Access,
         "Phase 407 Character Delete Boundary Transform Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase407_Character_Delete_State_Find_Clipboard_Navigation_Render'Access,
         "Phase 407 Character Delete State Find Clipboard Navigation Render");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase407_Character_Delete_Mixed_Command_Coexistence_Workflows'Access,
         "Phase 407 Character Delete Mixed Command Coexistence Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase407_Character_Delete_Active_Buffer_Routes_And_Persistence'Access,
         "Phase 407 Character Delete Active Buffer Routes And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase408_Character_Delete_Canonical_Surface_Cleanup'Access,
         "Phase 408 Character Delete Canonical Surface Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase408_Character_Delete_Canonical_Routes_State_And_Persistence'Access,
         "Phase 408 Character Delete Canonical Routes State And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase409_Selection_Delete_Command_Descriptors_And_Routes'Access,
         "Phase 409 Selection Delete Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase409_Selection_Delete_Range_Matrix_And_Backward_Selection'Access,
         "Phase 409 Selection Delete Source_Span Matrix And Backward Selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase409_Selection_Delete_Undo_Redo_Clipboard_Navigation_And_No_Op'Access,
         "Phase 409 Selection Delete Undo Redo Clipboard Navigation And No Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase410_Selection_Delete_Transform_Matrix_And_Caret'Access,
         "Phase 410 Selection Delete Transform Matrix And Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase410_Selection_Delete_No_Op_Invalid_And_Redo_Preservation'Access,
         "Phase 410 Selection Delete No Op Invalid And Redo Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase410_Selection_Delete_Find_Dirty_Clipboard_And_Navigation'Access,
         "Phase 410 Selection Delete Find Dirty Clipboard And Navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase410_Selection_Delete_Availability_Render_And_Persistence_Boundaries'Access,
         "Phase 410 Selection Delete Availability Render And Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase410_Selection_Delete_Active_Buffer_Isolation'Access,
         "Phase 410 Selection Delete Active Buffer Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase410_Selection_Delete_Selection_Command_And_Edit_Coexistence'Access,
         "Phase 410 Selection Delete Selection Command And Edit Coexistence");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase411_Selection_Delete_Workflow_Transform_Matrix'Access,
         "Phase 411 Selection Delete Workflow Transform Matrix");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase411_Forward_Backward_Equivalence_And_Invalid_Noops'Access,
         "Phase 411 Forward Backward Equivalence And Invalid Noops");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase411_Undo_Redo_Dirty_Find_Clipboard_And_Navigation_Workflow'Access,
         "Phase 411 Undo Redo Dirty Find Clipboard And Navigation Workflow");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase411_Command_Coexistence_And_Cut_Contrast'Access,
         "Phase 411 Command Coexistence And Cut Contrast");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase411_Read_Only_Routes_Feature_And_Persistence_Boundaries'Access,
         "Phase 411 Read Only Routes Feature And Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase412_Selection_Delete_Canonical_Surface_Cleanup'Access,
         "Phase 412 Selection Delete Canonical Surface Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase412_Selection_Delete_Canonical_State_Only_Workflow'Access,
         "Phase 412 Selection Delete Canonical State Only Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase413_Text_Insert_Basic_Caret_And_Undo'Access,
         "Phase 413 Text Insert Basic Caret And Undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase413_Text_Insert_Replaces_Selection_Without_Clipboard'Access,
         "Phase 413 Text Insert Replaces Selection Without Clipboard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase413_Input_Bridge_Routes_Editor_Text_And_Protects_Overlays'Access,
         "Phase 413 Input Bridge Routes Editor Text And Protects Overlays");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase413_Completeness_Noop_Invalid_And_Redo_Boundaries'Access,
         "Phase 413 Completeness Noop Invalid And Redo Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase413_Completeness_Backward_Cross_Line_Replacement_And_Persistence'Access,
         "Phase 413 Completeness Backward Cross Line Replacement And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase413_Completeness_Unicode_Routing_Internal_Surface_And_Isolation'Access,
         "Phase 413 Completeness Unicode Routing Internal Surface And Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase413_Remove_Removed_Name_Text_Input_Uses_Canonical_Path'Access,
         "Phase 413 Completeness Text Insert Uses Canonical Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase413_Completeness_Line_Boundary_Command_Is_Canonical_Insert'Access,
         "Phase 413 Completeness Line Boundary Command Is Canonical Insert");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase413_Completeness_Multi_Caret_Insert_Is_Not_Second_Model'Access,
         "Phase 413 Completeness Multi Caret Insert Is Not Second Model");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase414_Text_Insert_Caret_Transform_Matrix'Access,
         "Phase 414 Text Insert Caret Transform Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase414_Text_Insert_Replacement_Transform_Matrix'Access,
         "Phase 414 Text Insert Replacement Transform Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase414_Text_Insert_Noop_Invalid_And_Redo_Are_NonMutating'Access,
         "Phase 414 Text Insert Noop Invalid And Redo Are NonMutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase414_Text_Insert_Invalid_Selection_Does_Not_Repair_State'Access,
         "Phase 414 Text Insert Invalid Selection Does Not Repair State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase414_Text_Insert_Find_Clipboard_Navigation_And_Persistence'Access,
         "Phase 414 Text Insert Find Clipboard Navigation And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase414_Completeness_Active_Buffer_Render_And_Overlay_Routing'Access,
         "Phase 414 Completeness Active Buffer Render And Overlay Routing");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase415_Text_Insert_Workflow_Transform_And_Replacement'Access,
         "Phase 415 Text Insert Workflow Transform And Replacement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase415_Text_Insert_Noops_Redo_Dirty_And_Find'Access,
         "Phase 415 Text Insert Noops Redo Dirty And Find");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase415_Text_Insert_Clipboard_Navigation_Active_Buffer_And_Overlay_Workflow'Access,
         "Phase 415 Text Insert Clipboard Navigation Active Buffer And Overlay Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase415_Text_Insert_Mixed_Editing_Features_Render_And_Persistence'Access,
         "Phase 415 Text Insert Mixed Editing Features Render And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase415_Text_Insert_Overlay_Owner_Matrix_And_Command_Surface'Access,
         "Phase 415 Text Insert Overlay Owner Matrix And Command Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase416_Text_Insert_Canonical_Route_State_And_Persistence'Access,
         "Phase 416 Text Insert Canonical Route State And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase416_Text_Insert_Behavior_Preservation_Smoke'Access,
         "Phase 416 Text Insert Behavior Preservation Smoke");
   end Register_Tests;

end Editor.Line_Edit.Tests;
