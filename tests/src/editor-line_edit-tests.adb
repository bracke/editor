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
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Find_Replace_Commands;
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

   procedure Test_Command_Descriptors
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
   end Test_Command_Descriptors;

   procedure Test_Delete_Current_Line_Undo_Redo
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
   end Test_Delete_Current_Line_Undo_Redo;

   procedure Test_Duplicate_Current_Line
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
   end Test_Duplicate_Current_Line;

   procedure Test_Move_Line_Up_Down_And_Boundaries
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
   end Test_Move_Line_Up_Down_And_Boundaries;

   procedure Test_Empty_Buffer_No_Ops
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
   end Test_Empty_Buffer_No_Ops;

   procedure Test_Delete_First_Last_And_One_Line
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
   end Test_Delete_First_Last_And_One_Line;

   procedure Test_Duplicate_Last_Line_Undo_Redo
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
   end Test_Duplicate_Last_Line_Undo_Redo;

   procedure Test_Last_Line_Move_Down_No_Op_Preserves_Redo_Dirty
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
   end Test_Last_Line_Move_Down_No_Op_Preserves_Redo_Dirty;

   procedure Test_Clipboard_Selection_Navigation_Boundaries
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
   end Test_Clipboard_Selection_Navigation_Boundaries;



   procedure Test_Input_Bridge_Routes_Line_Commands
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
      Editor.Buffers.Reset_Global_For_Test;
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
      Editor.Buffers.Reset_Global_For_Test;
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
      Editor.Buffers.Reset_Global_For_Test;
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
      Editor.Buffers.Reset_Global_For_Test;
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
   end Test_Input_Bridge_Routes_Line_Commands;

   procedure Test_Availability_Has_No_Side_Effects
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
   end Test_Availability_Has_No_Side_Effects;


   procedure Test_Delete_Blank_Whitespace_And_EOF_Lines
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
   end Test_Delete_Blank_Whitespace_And_EOF_Lines;

   procedure Test_Duplicate_Whitespace_And_Caret_Clamp
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
   end Test_Duplicate_Whitespace_And_Caret_Clamp;

   procedure Test_Move_Blank_Line_And_Attached_Caret
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
   end Test_Move_Blank_Line_And_Attached_Caret;

   procedure Test_Redo_Find_And_Boundary_No_Op_Reliability
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
   end Test_Redo_Find_And_Boundary_No_Op_Reliability;

   procedure Test_Trailing_Newline_Line_Boundaries
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
   end Test_Trailing_Newline_Line_Boundaries;



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

   procedure Test_Delete_Duplicate_Move_Workflow_Consistency
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
   end Test_Delete_Duplicate_Move_Workflow_Consistency;

   procedure Test_Line_Terminator_Matrix_Undo_Redo
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
   end Test_Line_Terminator_Matrix_Undo_Redo;

   procedure Test_Selection_Clipboard_Find_Redo_Boundaries
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
   end Test_Selection_Clipboard_Find_Redo_Boundaries;

   procedure Test_Dirty_History_Clear_And_No_Op_Policy
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
   end Test_Dirty_History_Clear_And_No_Op_Policy;

   procedure Test_Availability_Projection_And_Non_Goal_Surface
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
   end Test_Availability_Projection_And_Non_Goal_Surface;

   procedure Test_Keybinding_Config_Rejects_Removed_Name_Line_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := "/tmp/editor-removed-name-line-keybindings";
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
   end Test_Keybinding_Config_Rejects_Removed_Name_Line_Names;

   procedure Test_Default_Keybindings_And_Runtime_Routes_Are_Canonical
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
   end Test_Default_Keybindings_And_Runtime_Routes_Are_Canonical;


   procedure Test_Indent_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      pragma Unreferenced (Id);

      procedure Assert_Not_Exposed (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found, Name & " must not be exposed in ");
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
      Assert_Not_Exposed ("edit.tabs.convert-to-spaces");
      Assert_Not_Exposed ("edit.tabs.convert-to-tabs");
   end Test_Indent_Command_Descriptors;


   procedure Test_Indent_Increase_Undo_Redo_And_Caret
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
   end Test_Indent_Increase_Undo_Redo_And_Caret;


   procedure Test_Indent_Increase_Blank_Whitespace_And_Empty_Buffer
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
   end Test_Indent_Increase_Blank_Whitespace_And_Empty_Buffer;


   procedure Test_Outdent_Policy_Undo_Redo_And_No_Op
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
   end Test_Outdent_Policy_Undo_Redo_And_No_Op;


   procedure Test_Indent_Selection_Clipboard_Find_And_Navigation_Boundaries
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
   end Test_Indent_Selection_Clipboard_Find_And_Navigation_Boundaries;


   procedure Test_Indent_Input_Bridge_And_Availability_Side_Effects
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
   end Test_Indent_Input_Bridge_And_Availability_Side_Effects;


   procedure Test_Leading_Whitespace_Outdent_Matrix
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
   end Test_Leading_Whitespace_Outdent_Matrix;


   procedure Test_Indent_Exact_Unit_And_Line_Boundaries
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
   end Test_Indent_Exact_Unit_And_Line_Boundaries;


   procedure Test_Redo_Find_Selection_Clipboard_And_Navigation_Reliability
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
   end Test_Redo_Find_Selection_Clipboard_And_Navigation_Reliability;


   procedure Test_Line_Edit_Coexistence_And_Current_Line_Only
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
   end Test_Line_Edit_Coexistence_And_Current_Line_Only;


   procedure Test_No_Caret_Render_Persistence_And_Non_Goals
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
      Assert (Found and then Id = Editor.Commands.Command_Format_Buffer,
              "format-document must resolve to the explicit buffer formatter");
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
   end Test_No_Caret_Render_Persistence_And_Non_Goals;


   procedure Test_Indent_Increase_Workflow_Matrix
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
   end Test_Indent_Increase_Workflow_Matrix;


   procedure Test_Outdent_Workflow_And_Whitespace_Matrix
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
   end Test_Outdent_Workflow_And_Whitespace_Matrix;


   procedure Test_Selection_Clipboard_Line_Edit_Integration
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
   end Test_Selection_Clipboard_Line_Edit_Integration;


   procedure Test_Render_Availability_And_Persistence_Are_Read_Only
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
   end Test_Render_Availability_And_Persistence_Are_Read_Only;
procedure Test_Line_Comment_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      pragma Unreferenced (Id);

      procedure Assert_Not_Exposed (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found, Name & " must not be exposed in ");
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
   end Test_Line_Comment_Command_Descriptors;


   procedure Test_Comment_Line_Prefix_Matrix_Undo_Redo
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
   end Test_Comment_Line_Prefix_Matrix_Undo_Redo;


   procedure Test_Uncomment_And_Toggle_Policies
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
   end Test_Uncomment_And_Toggle_Policies;


   procedure Test_No_Op_Redo_Empty_And_Active_Buffer_Isolation
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

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (B_Id /= A_Id, "new buffer must be a distinct active buffer");
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "-- Beta",
              "comment-line must mutate the active buffer");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha",
              "comment-line must not mutate inactive buffers");
      Assert (Editor.History.Undo_Stack.Is_Empty,
              "inactive buffer must not inherit line-comment undo entries");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "-- Beta",
              "switching back must restore active buffer line-comment text");
      Assert (not Editor.History.Undo_Stack.Is_Empty,
              "active buffer must retain its own line-comment undo entry");
   end Test_No_Op_Redo_Empty_And_Active_Buffer_Isolation;


   procedure Test_Indentation_And_Line_Editing_Coexistence
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
   end Test_Indentation_And_Line_Editing_Coexistence;


   procedure Test_Line_Comment_Edge_Matrix_And_Redo_Preservation
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
   end Test_Line_Comment_Edge_Matrix_And_Redo_Preservation;


   procedure Test_Boundaries_Availability_And_Persistence
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
   end Test_Boundaries_Availability_And_Persistence;



   procedure Test_Prefix_Matrix_And_Current_Line_Only
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
              "comment-line must insert exactly canonical marker at unindented prefix");

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
              "comment-line prefix matrix must preserve indentation, internal markers, and whitespace lines");

      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 4, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (S) = "Line already commented",
              "comment-line must no-op on -- space prefix");
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 5, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (S) = "Line already commented",
              "comment-line must no-op on bare -- prefix");

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
              "uncomment-line matrix must remove exactly one recognized prefix marker only");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A" & ASCII.LF & "B" & ASCII.LF & "C");
      Set_Primary_Selection
        (S,
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 0)),
         Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "A" & ASCII.LF & "-- B" & ASCII.LF & "C",
              "line-comment commands must operate on the caret line only, not selected-line ranges");
   end Test_Prefix_Matrix_And_Current_Line_Only;


   procedure Test_Caret_Selection_Find_Clipboard_Navigation
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
              "comment-line must insert after indentation regardless of caret column");
      Assert_Caret_Row_Col (S, 0, 7, "comment-line caret shift after insertion");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful comment-line must clear stale active selection");
      Assert (S.Active_Find_Stale,
              "text-changing comment-line must invalidate active Find through edit hook");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Omega") and then S.Active_Replace_Prompt,
              "line-comment must not mutate Replace text or visibility");
      Assert (Editor.Clipboard.Has_Text and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "line-comment must not mutate clipboard");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "line-comment must not record navigation history");

      S.Active_Find_Stale := False;
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 0, 3)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "  Alpha" & ASCII.LF & "Beta",
              "uncomment-line must restore exact pre-comment text");
      Assert_Caret_Row_Col (S, 0, 2,
                            "uncomment-line caret inside marker must clamp to marker position");
      Assert (S.Active_Find_Stale,
              "text-changing uncomment-line must invalidate active Find through edit hook");
      Assert (Editor.Clipboard.Has_Text and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "uncomment-line must preserve clipboard");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "uncomment-line must not record navigation history");
   end Test_Caret_Selection_Find_Clipboard_Navigation;


   procedure Test_Redo_Dirty_And_No_Op_Policy
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
              "text-changing comment-line must dirty a clean buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "comment-line must create one undo entry");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha",
              "undo after comment-line must restore exact previous text");
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Message_Text (S) = "Nothing to uncomment",
              "no-marker uncomment-line must report deterministic no-op");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "no-op uncomment-line after undo must preserve redo stack");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "no-op uncomment-line must not create undo entries");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "-- Alpha",
              "redo after no-op uncomment-line must still be available");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "successful comment-line after undo must clear redo stack");
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (S) = "Line already commented",
              "duplicate comment-line must report already-commented no-op");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "already-commented no-op must preserve redo stack");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "already-commented no-op must not create undo entry");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "",
              "toggle on empty buffer must preserve empty text");
      Assert (Message_Text (S) = "Nothing to comment",
              "toggle on empty buffer must use comment no-op message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "empty-buffer toggle must not create undo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "empty-buffer toggle must not dirty buffer");
   end Test_Redo_Dirty_And_No_Op_Policy;


   procedure Test_Indentation_Line_Edit_And_Toggle_Sharing
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
              "toggle comment path must place marker after current indentation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma",
              "outdent after comment-line must treat indentation canonically before marker");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
              "toggle uncomment path must share canonical marker recognition");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma",
              "duplicate-line after comment-line must preserve exact current-line text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma" & ASCII.LF & "-- Beta",
              "move-down after comment-line must preserve exact line boundaries");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma" & ASCII.LF & "Beta",
              "uncomment after line-edit commands must use post-edit caret line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma",
              "mixed line-comment and line-edit undo sequence must restore exact text");
   end Test_Indentation_Line_Edit_And_Toggle_Sharing;


   procedure Test_Completeness_Toggle_No_Op_Find_And_Persistence
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
                       "completeness toggle comments plain line");
      Run_Toggle_Case ("-- Alpha", "Alpha", "Uncommented line", 1,
                       "completeness toggle uncomments spaced marker");
      Run_Toggle_Case ("--Alpha", "Alpha", "Uncommented line", 1,
                       "completeness toggle uncomments bare marker");
      Run_Toggle_Case ("  Alpha", "  -- Alpha", "Commented line", 1,
                       "completeness toggle preserves leading spaces");
      Run_Toggle_Case ("  -- Alpha", "  Alpha", "Uncommented line", 1,
                       "completeness toggle removes marker after leading spaces");
      Run_Toggle_Case ("Alpha -- x", "-- Alpha -- x", "Commented line", 1,
                       "completeness toggle treats internal marker as ordinary text");
      Run_Toggle_Case ("  ", "  -- ", "Commented line", 1,
                       "completeness toggle comments whitespace-only line");
      Run_Toggle_Case ("", "", "Nothing to comment", 0,
                       "completeness toggle empty-buffer no-op");

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
              "no-op comment-line must preserve text exactly");
      Assert (Message_Text (S) = "Line already commented",
              "no-op comment-line must report already-commented status");
      Assert (not S.Active_Find_Stale,
              "no-op comment-line must not invalidate Find/Replace");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Alpha"),
              "no-op comment-line must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Beta")
              and then S.Active_Replace_Prompt,
              "no-op comment-line must not mutate Replace state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "no-op comment-line must not create an undo entry");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha -- note");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("--");
      S.Active_Find_Stale := False;
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha -- note",
              "no-op uncomment-line must not remove an internal marker");
      Assert (Message_Text (S) = "Nothing to uncomment",
              "no-op uncomment-line must report deterministic no-op");
      Assert (not S.Active_Find_Stale,
              "no-op uncomment-line must not invalidate Find/Replace");

      Workspace_Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace_Snap));
      Assert
        (Index (Summary, "comment marker") = 0
         and then Index (Summary, "last commented") = 0
         and then Index (Summary, "last uncommented") = 0
         and then Index (Summary, "line comment") = 0,
         "workspace snapshot must not persist line-comment transient state");
   end Test_Completeness_Toggle_No_Op_Find_And_Persistence;


   procedure Test_Completeness_Read_Only_Routes_And_No_Active_Buffer
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
         "completeness comment-line");
      Assert_Stable_Name
        ("edit.uncomment.line",
         Editor.Commands.Command_Uncomment_Line,
         "completeness uncomment-line");
      Assert_Stable_Name
        ("edit.comment.toggle-line",
         Editor.Commands.Command_Toggle_Line_Comment,
         "completeness toggle-line-comment");
      Assert_Removed_Name_Absent
        ("edit.comment.current-line",
         "completeness removed current-line comment alias");
      Assert_Removed_Name_Absent
        ("edit.line.comment",
         "completeness removed line-comment alias");
      Assert_Removed_Name_Absent
        ("edit.toggle-comment.line",
         "completeness removed toggle-comment alias");

      Assert_No_Buffer_Command
        (Editor.Commands.Command_Comment_Line,
         "No active buffer.",
         "completeness comment-line no active buffer");
      Assert_No_Buffer_Command
        (Editor.Commands.Command_Uncomment_Line,
         "No active buffer.",
         "completeness uncomment-line no active buffer");
      Assert_No_Buffer_Command
        (Editor.Commands.Command_Toggle_Line_Comment,
         "No active buffer.",
         "completeness toggle-line-comment no active buffer");

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
              "completeness comment-line availability should be available");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Editor.Commands.Is_Available (Avail),
              "completeness uncomment-line availability should be available");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Editor.Commands.Is_Available (Avail),
              "completeness toggle availability should be available");
      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "completeness render snapshot must observe text length only");

      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "completeness read-only paths must not mutate buffer text");
      Assert (S.Active_Find_Query = Before_Find
              and then not S.Active_Find_Stale,
              "completeness read-only paths must not mutate Find state");
      Assert (S.Active_Replace_Text = Before_Replace
              and then S.Active_Replace_Prompt,
              "completeness read-only paths must not mutate Replace state");
      Assert (Editor.Selection.Has_Selection (S),
              "completeness read-only paths must not normalize selection");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "completeness read-only paths must not mutate dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "completeness read-only paths must not mutate history stacks");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "completeness read-only paths must not move caret");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "completeness read-only paths must not mutate clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "completeness read-only paths must not mutate navigation history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "  Alpha" & ASCII.LF & "Beta -- internal",
              "completeness uncomment-line must remove only the active-line canonical marker");
      Assert (S.Active_Find_Query = Before_Find
              and then S.Active_Replace_Text = Before_Replace
              and then S.Active_Replace_Prompt,
              "completeness text-changing comment command must not rewrite Find/Replace payloads");
      Assert (S.Active_Find_Stale,
              "completeness text-changing comment command must invalidate Find matches");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "completeness text-changing command must preserve clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "completeness text-changing command must not mutate navigation history");
      Assert (not Editor.Selection.Has_Selection (S),
              "completeness text-changing command must clear/collapse selection");
   end Test_Completeness_Read_Only_Routes_And_No_Active_Buffer;



   procedure Test_Completeness_Line_Boundaries_And_No_Caret
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
         "completeness must comment first, blank, whitespace-only, and trailing-newline last lines exactly");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 4,
              "completeness line-boundary mutations must create one undo entry per text change");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "First" & ASCII.LF & ASCII.LF & "  " & ASCII.LF & "Last" & ASCII.LF,
         "completeness undo chain must restore exact line terminators and blank lines");
      Assert (not Editor.State.Is_Dirty (S),
              "completeness undo to clean baseline must restore clean dirty state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "-- First" & ASCII.LF & ASCII.LF & "  " & ASCII.LF & "Last" & ASCII.LF,
         "completeness redo must replay line-comment text mutation without re-running classification on later lines");
      Assert_Caret_Row_Col (S, 0, 5,
                            "completeness redo after comment-line must restore canonical caret position");

      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Dirty := Editor.State.Is_Dirty (S);
      S.Carets.Clear;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (S) = "No caret location",
              "completeness comment-line without a caret must report no caret location");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "completeness no-caret comment-line must not mutate buffer text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "completeness no-caret comment-line must preserve undo and redo stacks");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "completeness no-caret comment-line must preserve dirty state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Message_Text (S) = "No caret location",
              "completeness uncomment-line without a caret must report no caret location");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Message_Text (S) = "No caret location",
              "completeness toggle-line-comment without a caret must report no caret location");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "completeness no-caret uncomment/toggle must not mutate buffer text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "completeness no-caret uncomment/toggle must preserve undo and redo stacks");
   end Test_Completeness_Line_Boundaries_And_No_Caret;


   procedure Test_Completeness_Active_Buffer_Isolation
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

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Buffer_B := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "Gamma" & ASCII.LF & "Delta");
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Gamma" & ASCII.LF & "-- Delta",
              "completeness active-buffer command must mutate only current buffer text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "completeness active-buffer command must create active-buffer undo only");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Buffer_A);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "Beta",
              "completeness inactive buffer A text must remain unchanged by buffer B comment command");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "completeness inactive buffer A undo stack must remain unchanged");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Message_Text (S) = "Nothing to uncomment",
              "completeness active buffer A must independently classify its current line");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "completeness no-op on buffer A must not synthesize redo history");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Buffer_B);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Gamma" & ASCII.LF & "-- Delta",
              "completeness buffer B comment text must persist across active-buffer switch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "completeness buffer B undo stack must remain isolated and available");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Gamma" & ASCII.LF & "Delta",
              "completeness undo after switching back to buffer B must affect only buffer B");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Buffer_A);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "Alpha" & ASCII.LF & "Beta",
              "completeness buffer B undo must not mutate buffer A text");
      Assert (Editor.Buffers.Global_Active_Buffer = Buffer_A,
              "completeness line-comment commands must not activate another buffer");
   end Test_Completeness_Active_Buffer_Isolation;



   procedure Test_Line_Comment_Workflow_Matrices
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
                "comment plain line");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "  Alpha", "  -- Alpha", "Commented line", 1,
                "comment leading spaces");
      Run_Case (Editor.Commands.Command_Comment_Line,
                String'(1 => ASCII.HT) & "Alpha",
                String'(1 => ASCII.HT) & "-- Alpha",
                "Commented line", 1,
                "comment leading tab");
      Run_Case (Editor.Commands.Command_Comment_Line,
                " " & String'(1 => ASCII.HT) & "Alpha",
                " " & String'(1 => ASCII.HT) & "-- Alpha",
                "Commented line", 1,
                "comment mixed whitespace prefix");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "-- Alpha", "-- Alpha", "Line already commented", 0,
                "comment spaced prefix no-op");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "--Alpha", "--Alpha", "Line already commented", 0,
                "comment bare prefix no-op");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "Alpha -- note", "-- Alpha -- note", "Commented line", 1,
                "comment internal marker as text");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "  ", "  -- ", "Commented line", 1,
                "comment whitespace-only line");
      Run_Case (Editor.Commands.Command_Comment_Line,
                "", "", "Nothing to comment", 0,
                "comment empty buffer");

      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "-- Alpha", "Alpha", "Uncommented line", 1,
                "uncomment spaced marker");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "--Alpha", "Alpha", "Uncommented line", 1,
                "uncomment bare marker");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "  -- Alpha", "  Alpha", "Uncommented line", 1,
                "uncomment spaces before marker");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                String'(1 => ASCII.HT) & "-- Alpha",
                String'(1 => ASCII.HT) & "Alpha",
                "Uncommented line", 1,
                "uncomment tab before marker");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "Alpha -- note", "Alpha -- note", "Nothing to uncomment", 0,
                "uncomment internal marker no-op");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "  -- ", "  ", "Uncommented line", 1,
                "uncomment comment-only indented line");
      Run_Case (Editor.Commands.Command_Uncomment_Line,
                "--", "", "Uncommented line", 1,
                "uncomment bare marker-only line");

      Run_Case (Editor.Commands.Command_Toggle_Line_Comment,
                "Alpha", "-- Alpha", "Commented line", 1,
                "toggle comments absent marker");
      Run_Case (Editor.Commands.Command_Toggle_Line_Comment,
                "-- Alpha", "Alpha", "Uncommented line", 1,
                "toggle uncomments spaced marker");
      Run_Case (Editor.Commands.Command_Toggle_Line_Comment,
                "Alpha -- x", "-- Alpha -- x", "Commented line", 1,
                "toggle treats internal marker as ordinary text");

      Run_Redo_Preservation
        (Editor.Commands.Command_Comment_Line, "-- Alpha",
         "Line already commented",
         "already-commented command preserves redo");
      Run_Redo_Preservation
        (Editor.Commands.Command_Uncomment_Line, "Alpha -- note",
         "Nothing to uncomment",
         "no-marker uncomment preserves redo");
   end Test_Line_Comment_Workflow_Matrices;


   procedure Test_Line_Boundaries_Caret_Selection_And_Find
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
         "comment must mutate only the caret logical line");
      Assert_Caret_Row_Col (S, 1, 4,
                            "comment must keep caret valid on same logical line");
      Assert (not Editor.Selection.Has_Selection (S),
              "text-changing comment must clear/collapse active selection");
      Assert (S.Active_Find_Stale,
              "text-changing comment must invalidate Find ranges");
      Assert (S.Active_Find_Query = To_Unbounded_String ("B")
              and then S.Active_Replace_Text = To_Unbounded_String ("Bee")
              and then S.Active_Replace_Prompt,
              "line comment must not mutate Find query or Replace text");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "line comment must not consume clipboard while selection is present");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "line comment caret normalization must not record navigation");

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
         "blank, whitespace-only, and tab-leading lines must follow exact marker policy");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 4,
              "each text-changing line-comment command must create exactly one undo entry");

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
         "undo chain must restore exact line boundaries and terminators");
      Assert (not Editor.State.Is_Dirty (S),
              "undo to saved baseline must restore clean dirty state");

      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot must observe current buffer length after undo");
   end Test_Line_Boundaries_Caret_Selection_And_Find;


   procedure Test_Indent_Line_Edit_Clipboard_And_Redo_Integration
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
              "setup indent must adjust leading whitespace before comment marker");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "  -- Beta" & ASCII.LF & "Gamma",
              "comment after indent must insert marker after current leading whitespace");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF & "Gamma",
              "outdent after comment must treat indentation before marker canonically");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
              "uncomment after outdent must remove only canonical active-line marker");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF &
              "-- Beta" & ASCII.LF & "Gamma",
              "duplicate-line after comment must preserve exact commented text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF &
              "Gamma" & ASCII.LF & "-- Beta",
              "move-down after duplicate/comment must preserve logical line boundaries");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "-- Beta" & ASCII.LF &
              "Gamma" & ASCII.LF & "Beta",
              "toggle after line move must classify post-edit current line");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "indentation/line-edit/comment integration must not mutate clipboard");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "undo after mixed workflow must expose redo");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "successful line-comment command after undo must clear redo");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Message_Text (S) = "No edits to redo",
              "redo after successful line-comment invalidation must report no redo");
   end Test_Indent_Line_Edit_Clipboard_And_Redo_Integration;


   procedure Test_Read_Only_Routes_Feature_Independence_And_Persistence
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
              "comment availability must be side-effect-free and available");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Editor.Commands.Is_Available (Avail),
              "uncomment availability must be side-effect-free and available");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Editor.Commands.Is_Available (Avail),
              "toggle availability must be side-effect-free and available");
      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot must derive from canonical buffer text");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text)
              and then S.Active_Find_Query = Before_Find
              and then S.Active_Replace_Text = Before_Replace
              and then not S.Active_Find_Stale
              and then Editor.Selection.Has_Selection (S)
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "render/availability paths must not mutate editor state");

      Editor.State.Init (No_Buffer);
      Editor.Executor.Execute_Command (No_Buffer, Editor.Commands.Command_Comment_Line);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "comment-line without active buffer must report canonical message");
      Editor.Executor.Execute_Command (No_Buffer, Editor.Commands.Command_Uncomment_Line);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "uncomment-line without active buffer must report canonical message");
      Editor.Executor.Execute_Command (No_Buffer, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "toggle-line-comment without active buffer must report canonical message");

      Editor.Keybindings.Bind (Ctrl_Slash, Editor.Commands.Command_Toggle_Line_Comment);
      Binding := Editor.Keybindings.Resolve (Ctrl_Slash, Resolved);
      Assert (Binding = Editor.Keybindings.Bound_Command
              and then Resolved = Editor.Commands.Command_Toggle_Line_Comment,
              "runtime keybinding must resolve to canonical toggle-line-comment id");

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
         "workspace persistence must exclude line-comment transient state/settings");

      Assert_Not_Exposed ("edit.comment.selection",
                          "selected-line comment command must remain absent");
      Assert_Not_Exposed ("edit.uncomment.selection",
                          "selected-line uncomment command must remain absent");
      Assert_Not_Exposed ("edit.comment.block",
                          "block comment command must remain absent");
      Assert_Not_Exposed ("edit.comment.toggle-block",
                          "toggle block comment command must remain absent");
      Assert_Not_Exposed ("edit.comment.smart",
                          "smart comment command must remain absent");
      Assert_Not_Exposed ("edit.comment.language-aware",
                          "language-aware comment command must remain absent");
      Assert_Not_Exposed ("edit.comment.document",
                          "document comment command must remain absent");
      Assert_Not_Exposed ("edit.comment.region",
                          "region comment command must remain absent");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("edit.format.on-save", Found) =
         Editor.Commands.Command_Toggle_Format_On_Save
         and then Found,
         "format-on-save alias should resolve to the persisted save formatter command");
   end Test_Read_Only_Routes_Feature_Independence_And_Persistence;

procedure Test_Canonical_Line_Comment_Path_And_Persistence_Exclusion
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
         "comment-line must use the canonical marker and leading-prefix helper");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "comment-line must create exactly one canonical undo entry");
      Assert (Editor.State.Is_Dirty (S),
              "comment-line must dirty through canonical policy");
      Assert (S.Active_Find_Stale,
              "comment-line must invalidate Find through canonical edit hook");
      Assert (S.Active_Replace_Text = Before_Replace,
              "comment-line must not mutate Replace text");
      Assert (Editor.Clipboard.Has_Text and then Editor.Clipboard.Get_Text = Before_Clip,
              "comment-line must not mutate Clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "comment-line must not record Navigation History");

      S.Active_Find_Stale := False;
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 2, 1)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "  -- Beta -- internal" & ASCII.LF & "Gamma",
         "toggle-line must use the same canonical removable-marker path as uncomment-line");
      Assert (Message_Text (S) = "Uncommented line",
              "toggle-line must emit one operation-specific primary message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 2,
              "toggle-line must create one undo entry, not two");
      Assert (S.Active_Find_Stale,
              "toggle-line must invalidate Find through canonical edit hook");

      S.Active_Find_Stale := False;
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 10)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert
        (Text_Buffer.UTF8_Text (S.Buffer) =
         "Alpha" & ASCII.LF & "  Beta -- internal" & ASCII.LF & "Gamma",
         "uncomment-line must remove only one canonical prefix marker");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert (Text_Buffer.UTF8_Text (S.Buffer) =
              "Alpha" & ASCII.LF & "  Beta -- internal" & ASCII.LF & "Gamma",
              "no-op uncomment-line must not remove internal markers");
      Assert (Message_Text (S) = "Nothing to uncomment",
              "no-op uncomment-line must report deterministic no-op");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 3,
              "no-op uncomment-line must not create an undo entry");
      Assert (S.Active_Find_Stale,
              "no-op after prior edit must not repair stale state");

      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot must derive from canonical buffer text only");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert (Editor.Commands.Is_Available (Avail),
              "toggle availability must remain side-effect-free and available");

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
         "workspace persistence must exclude canonical and removed line-comment state/settings");
   end Test_Canonical_Line_Comment_Path_And_Persistence_Exclusion;


   procedure Test_Line_Join_Command_Descriptors
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
   end Test_Line_Join_Command_Descriptors;


   procedure Test_Join_Next_Separator_Matrix_Undo_Redo
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
   end Test_Join_Next_Separator_Matrix_Undo_Redo;


   procedure Test_Join_Next_Boundaries_Redo_And_Caret
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
   end Test_Join_Next_Boundaries_Redo_And_Caret;


   procedure Test_Join_Next_Boundaries_Selection_Find_Clipboard_Navigation
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
   end Test_Join_Next_Boundaries_Selection_Find_Clipboard_Navigation;


   procedure Test_Join_Next_Coexists_With_Line_Edit_Indent_And_Comment
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
   end Test_Join_Next_Coexists_With_Line_Edit_Indent_And_Comment;


   procedure Test_Join_Next_Does_Not_Add_Forbidden_Aliases_Or_State
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
              "must not add selected-line join command aliases");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.join.smart", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "must not add smart/language-aware join aliases");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.paragraph.reflow", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              "must not add paragraph reflow aliases");

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
         "must persist no Line Join transient state or settings");
   end Test_Join_Next_Does_Not_Add_Forbidden_Aliases_Or_State;


   procedure Test_Join_Next_Input_Bridge_Route
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
   end Test_Join_Next_Input_Bridge_Route;


   procedure Test_Join_Next_Separator_And_Boundary_Reliability
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
   end Test_Join_Next_Separator_And_Boundary_Reliability;


   procedure Test_Join_Next_No_Op_Redo_Dirty_And_Find_Policy
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
   end Test_Join_Next_No_Op_Redo_Dirty_And_Find_Policy;


   procedure Test_Join_Next_Caret_Selection_Clipboard_Navigation_And_Render
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
   end Test_Join_Next_Caret_Selection_Clipboard_Navigation_And_Render;


   procedure Test_Join_Next_Mixed_Current_Line_Command_Workflows
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
   end Test_Join_Next_Mixed_Current_Line_Command_Workflows;


   procedure Test_Join_Next_End_To_End_And_Separator_Workflows
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
   end Test_Join_Next_End_To_End_And_Separator_Workflows;


   procedure Test_Join_Next_Caret_Selection_Find_Clipboard_And_Render_Workflow
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
              "render snapshot must not join or repair text");
      Assert (Snap.Selection_Count = 1,
              "render snapshot must expose the pre-join selection without consuming it");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Join_Next);
      Assert (To_Unbounded_String (Buffer_Text (S)) = Before_Text,
              "availability must not mutate text");
      Assert (Editor.Selection.Has_Selection (S),
              "availability must not collapse selection");
      Assert (S.Active_Find_Query = Before_Query
              and then S.Active_Replace_Text = Before_Replace
              and then S.Active_Replace_Prompt,
              "availability must not mutate Find/Replace state");

      Set_Primary_Selection
        (S, 0, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 2)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);

      Assert_Line_Join_Coherent
        (S, "Alpha" & ASCII.LF & "Beta Gamma", 2, 1, 2,
         1, 0, "Joined line", True, False, Before_Clip,
         Before_Back, Before_Forward,
         "selected text is not consumed; caret line joins only next line");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "text-changing join must invalidate Find ranges");
      Assert (S.Active_Find_Query = Before_Query,
              "Line Join must not mutate Find query");
      Assert (S.Active_Replace_Text = Before_Replace and then S.Active_Replace_Prompt,
              "Line Join must not mutate Replace prompt/text");

      Snap := Editor.Render_Model.Build_Snapshot (S);
      Assert (Snap.Primary_Caret_Row = 1 and then Snap.Primary_Caret_Col = 2,
              "render snapshot must derive caret from canonical post-join state");
      Assert (Snap.Selection_Count = 0,
              "render snapshot must not render stale pre-join selection");
      Assert (Snap.Active_Find_Match_Count = 0,
              "render snapshot must not render stale pre-join Find ranges");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
                          "undo restores exact pre-join text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta Gamma",
                          "redo restores exact post-join text");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Undo/Redo around Line Join must not mutate Clipboard");
      Assert_Navigation_Counts (S, Before_Back, Before_Forward,
                                "Undo/Redo around Line Join must not record Navigation History");
   end Test_Join_Next_Caret_Selection_Find_Clipboard_And_Render_Workflow;


   procedure Test_Join_Next_Redo_Dirty_And_Mixed_Command_Coexistence
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
      Assert_Buffer_Text (S, "one two", "initial join for redo invalidation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "one" & ASCII.LF & "two",
                          "undo before redo invalidation restores baseline");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "ordinary successful edit after undo clears redo stack");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "no-op last-line join must preserve redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "  one" & ASCII.LF & "two",
                          "redo after no-op join restores preserved redo edit");

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
                          "duplicate-line precondition");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Alpha   Beta" & ASCII.LF & "Gamma",
                          "duplicate-line then join uses canonical logical boundary");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "-- Alpha   Beta" & ASCII.LF & "Gamma",
                          "comment-line after join treats joined line as plain text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Alpha   Beta" & ASCII.LF & "Gamma",
                          "uncomment-line after join removes only canonical prefix marker");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "  Alpha   Beta" & ASCII.LF & "Gamma",
                          "indent after join operates on joined logical line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Alpha   Beta" & ASCII.LF & "Gamma",
                          "outdent after join operates on joined logical line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Gamma" & ASCII.LF & "Alpha   Beta",
                          "move-down after join keeps line boundaries deterministic");
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 0)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Delete);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Alpha   Beta",
                          "delete-line after join deletes the selected current logical line only");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "mixed current-line commands must not attribute Clipboard changes to Line Join");
   end Test_Join_Next_Redo_Dirty_And_Mixed_Command_Coexistence;


   procedure Test_Join_Next_Active_Buffer_Routes_Features_And_Persistence
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
                 "non-goal command must not be exposed: " & Name);
      end Assert_Not_Exposed;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "Delta" & ASCII.LF & "Epsilon" & ASCII.LF & "Zeta");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Set_Caret (S, 0);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "Alpha Beta" & ASCII.LF & "Gamma",
                          "join in buffer A changes only buffer A");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "buffer A join creates one active-buffer undo entry");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text (S, "Delta" & ASCII.LF & "Epsilon" & ASCII.LF & "Zeta",
                          "buffer B text remains unchanged after buffer A join");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "buffer B undo stack remains unchanged after buffer A join");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "Delta Epsilon" & ASCII.LF & "Zeta",
                          "buffer B joins independently");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Delta" & ASCII.LF & "Epsilon" & ASCII.LF & "Zeta",
                          "undo in buffer B affects only buffer B");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text (S, "Alpha Beta" & ASCII.LF & "Gamma",
                          "switching back preserves buffer A joined text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
                          "undo in buffer A affects only buffer A");

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
              "command palette must project exactly one canonical join-next command");
      Assert_Buffer_Text (S, "Quick" & ASCII.LF & "Open" & ASCII.LF & "Search",
                          "command palette projection must not join text");

      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "Quick Open" & ASCII.LF & "Search",
                          "route coverage command id must execute canonical join");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "route coverage join must not mutate Clipboard");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "route coverage join must not mutate Navigation History");

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
         "workspace persistence must exclude Line Join transient/settings state");

      Assert_Not_Exposed ("edit.line.join-selection");
      Assert_Not_Exposed ("edit.line.join-all");
      Assert_Not_Exposed ("edit.line.join-paragraph");
      Assert_Not_Exposed ("edit.line.split");
      Assert_Not_Exposed ("edit.paragraph.reflow");
      Assert_Not_Exposed ("edit.join.smart");
      Assert_Not_Exposed ("edit.join.language-aware");
   end Test_Join_Next_Active_Buffer_Routes_Features_And_Persistence;
procedure Test_Line_Join_Canonical_Behavior_And_Persistence
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
         "canonical Line Join behavior preservation");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Line Join must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("BETA"),
              "Line Join must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "Line Join must use canonical Find/Replace invalidation hook");

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text (S, "Alpha  " & ASCII.HT & "Beta" & ASCII.LF & "Gamma",
                          "render snapshot must not perform Line Join repairs");
      Assert (R.Primary_Caret_Row = 0,
              "render caret row must derive from canonical caret state");
      Assert (R.Selection_Count = 0,
              "render snapshot must not expose stale Line Join selection state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha " & ASCII.LF & ASCII.HT & "Beta" & ASCII.LF & "Gamma",
                          "undo must restore captured pre-join text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha  " & ASCII.HT & "Beta" & ASCII.LF & "Gamma",
                          "redo must restore captured post-join text without re-running join logic");

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
         "workspace persistence must exclude canonical and removed Line Join state/settings");
   end Test_Line_Join_Canonical_Behavior_And_Persistence;



   procedure Test_Line_Split_Command_Descriptors_And_Routes
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
         "split stable command name mismatch");
      Assert (Desc.Category = Editor.Commands.Edit_Category,
              "split must be an Edit command");
      Assert (Desc.Visibility = Editor.Commands.Palette_Command,
              "split must be visible in the Command Palette");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Line_Split_At_Caret),
         "split must be bindable");
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Cmd.Kind = Editor.Commands.Split_Current_Line_At_Caret,
              "split command must map to canonical edit kind");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.line.split-at-caret", Found);
      Assert (Found and then Id = Editor.Commands.Command_Line_Split_At_Caret,
              "split stable name must resolve back to command id");
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
              "split availability must not mutate text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "split availability must not move caret");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "split availability must not mutate undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "split availability must not mutate redo stack");
   end Test_Line_Split_Command_Descriptors_And_Routes;


   procedure Test_Line_Split_Boundary_Matrix_Undo_Redo
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
             "split in middle of one-line buffer");
      Check ("Alpha", 0,
             ASCII.LF & "Alpha", 1,
             "split at beginning of line");
      Check ("Alpha", 5,
             "Alpha" & ASCII.LF, 1,
             "split at end of line");
      Check ("", 0,
             String'(1 => ASCII.LF), 1,
             "split empty buffer as boundary insertion");
      Check ("  AlphaBeta", 2,
             "  " & ASCII.LF & "AlphaBeta", 1,
             "split preserves leading whitespace before caret");
      Check ("Alpha  Beta", 5,
             "Alpha" & ASCII.LF & "  Beta", 1,
             "split preserves whitespace after caret");
      Check ("one" & ASCII.LF & "twoThree" & ASCII.LF & "four", 7,
             "one" & ASCII.LF & "two" & ASCII.LF & "Three" & ASCII.LF & "four", 2,
             "split middle line only");
   end Test_Line_Split_Boundary_Matrix_Undo_Redo;


   procedure Test_Line_Split_State_Boundaries_And_Persistence
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
         "split state boundaries");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "split must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("BETA"),
              "split must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "split must use canonical Find/Replace invalidation hook");

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "render snapshot must not perform line splitting");
      Assert (R.Primary_Caret_Row = 1,
              "render caret row must derive from split caret state");
      Assert (R.Selection_Count = 0,
              "render snapshot must not expose stale split selection state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta Gamma",
         "split must coexist with canonical Line Join policy");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "undo after mixed split/join must restore split text");

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
         "workspace persistence must exclude Line Split transient state/settings");

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
              "Input_Bridge split keybinding must route through Executor");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Input_Bridge split route must create one undo entry");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Line_Split_State_Boundaries_And_Persistence;


   procedure Test_Completeness_No_Op_Redo_And_Boundaries
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
            "split availability without active buffer must report no active buffer");
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Line_Split_At_Caret);
         Assert (Message_Text (S) = "No active buffer.",
                 "split execution without active buffer must report no active buffer");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 0
                 and then Natural (Editor.History.Redo_Stack.Length) = 0,
                 "no-active-buffer split must not mutate history");
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
            "split availability without caret must report no caret location");
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Line_Split_At_Caret);
         Assert (Message_Text (S) = "No caret location",
                 "split execution without caret must report no caret location");
         Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
                 "no-caret split must not mutate text");
         Assert (Natural (Editor.History.Undo_Stack.Length) = 0
                 and then Natural (Editor.History.Redo_Stack.Length) = 0,
                 "no-caret split must not mutate history");
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
         "split blank line before tab-leading line");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, ASCII.LF & ASCII.HT & "Tabbed" & ASCII.LF & "Tail",
         "undo restores blank/tab-leading split source exactly");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, ASCII.LF & ASCII.LF & ASCII.HT & "Tabbed" & ASCII.LF & "Tail",
         "redo restores blank/tab-leading split result exactly");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "undo before failed split must leave one redo entry");
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer) + 20));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Message_Text (S) = "Could not split line",
              "invalid-caret split must report deterministic failure");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "failed split after undo must not mutate text");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "failed split after undo must preserve dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "failed split after undo must preserve undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "failed split after undo must preserve redo stack");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "failed split must not mutate clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "failed split must not mutate navigation history");

      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, To_String (Before_Text) & ASCII.LF,
         "successful split after undo must clear redo and append one boundary at EOF");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "successful split after undo must clear redo stack");
   end Test_Completeness_No_Op_Redo_And_Boundaries;

   procedure Test_Line_Split_Exact_Position_Matrix
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
             "split at line start");
      Check ("AlphaBeta", 5,
             "Alpha" & ASCII.LF & "Beta", 1,
             "split in middle of line");
      Check ("Alpha", 5,
             "Alpha" & ASCII.LF, 1,
             "split at line end");
      Check ("  Alpha", 2,
             "  " & ASCII.LF & "Alpha", 1,
             "split inside leading whitespace");
      Check ("  AlphaBeta", 7,
             "  Alpha" & ASCII.LF & "Beta", 1,
             "split after leading whitespace text");
      Check ("Alpha  Beta", 5,
             "Alpha" & ASCII.LF & "  Beta", 1,
             "split before trailing whitespace segment");
      Check ("Alpha  Beta", 7,
             "Alpha  " & ASCII.LF & "Beta", 1,
             "split after trailing whitespace segment");
      Check (ASCII.HT & "Alpha", 1,
             ASCII.HT & ASCII.LF & "Alpha", 1,
             "split after tab prefix");
      Check (ASCII.HT & "AlphaBeta", 6,
             ASCII.HT & "Alpha" & ASCII.LF & "Beta", 1,
             "split tab-leading text");
      Check ("   ", 3,
             "   " & ASCII.LF, 1,
             "split whitespace-only line end");
      Check ("", 0,
             String'(1 => ASCII.LF), 1,
             "empty buffer split uses canonical two-empty-lines representation");
      Check ("A" & ASCII.LF & "BC" & ASCII.LF & "D", 4,
             "A" & ASCII.LF & "B" & ASCII.LF & "C" & ASCII.LF & "D", 2,
             "split middle logical line in multiline buffer");
      Check ("A" & ASCII.LF & "B" & ASCII.LF & "C", 2,
             "A" & ASCII.LF & ASCII.LF & "B" & ASCII.LF & "C", 2,
             "split at start of middle logical line");
      Check ("A" & ASCII.LF & "B" & ASCII.LF & "C", 3,
             "A" & ASCII.LF & "B" & ASCII.LF & ASCII.LF & "C", 2,
             "split at end of middle logical line before terminator");
      Check ("A" & ASCII.LF & "B", 3,
             "A" & ASCII.LF & "B" & ASCII.LF, 2,
             "split at EOF appends exactly one canonical boundary");
   end Test_Line_Split_Exact_Position_Matrix;


   procedure Test_Line_Split_Selection_Find_Clipboard_Navigation_And_Render
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
         "split selection/find/clipboard/navigation boundaries");
      Assert (S.Active_Find_Query = To_Unbounded_String ("AlphaBeta"),
              "split must not mutate Find query text");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("A-B"),
              "split must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "split must invalidate active Find ranges through canonical text-edit hook");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "copy after split must observe cleared selection and preserve clipboard text");

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "render snapshot must not mutate split text");
      Assert (R.Primary_Caret_Row = 1 and then R.Primary_Caret_Col = 0,
              "render snapshot caret must reflect normalized split caret");
      Assert (R.Selection_Count = 0,
              "render snapshot must not expose stale cleared split selection");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "render/copy after split must not mutate navigation history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "AlphaBeta" & ASCII.LF & "Gamma",
         "undo after split restores exact text before selection split");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "undo after split leaves redo available");
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer) + 20));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Message_Text (S) = "Could not split line",
              "invalid injected caret split must fail deterministically");
      Assert_Buffer_Text
        (S, To_String (Before_Text),
         "failed invalid-caret split must not mutate text");
      Assert_Caret_Row_Col
        (S, 1, 5,
         "failed invalid-caret split clamps caret to canonical EOF");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "failed invalid-caret split must preserve dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "failed invalid-caret split must preserve undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "failed invalid-caret split must preserve redo stack");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "failed invalid-caret split must preserve clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "failed invalid-caret split must preserve navigation history");
   end Test_Line_Split_Selection_Find_Clipboard_Navigation_And_Render;


   procedure Test_Line_Split_Mixed_Current_Line_Command_Workflows
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
         "split creates one canonical logical boundary before join");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta Gamma",
         "split then join follows join separator policy and is not a semantic inverse");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "undo mixed split/join restores exact pre-join split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta Gamma",
         "redo mixed split/join restores exact joined text");

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
         "split inside leading whitespace does not auto-indent or copy indentation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert_Buffer_Text
        (S, "  " & ASCII.LF & "  AlphaBeta",
         "indent after split affects caret's new logical line only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "  " & ASCII.LF & "AlphaBeta",
         "undo indent after split restores exact split text");

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
         "split treats comment markers as plain text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert_Buffer_Text
        (S, "-- " & ASCII.LF & "-- AlphaBeta",
         "toggle comment after split operates on caret's new logical line only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "-- " & ASCII.LF & "AlphaBeta",
         "undo comment after split restores exact split text");

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
         "split after line editing setup uses logical line text only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "Mid" & ASCII.LF & "Tail" & ASCII.LF & "Tail" & ASCII.LF & "Bottom",
         "duplicate-line after split uses post-split current logical line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom",
         "mixed line-edit undo chain restores exact original text");
   end Test_Line_Split_Mixed_Current_Line_Command_Workflows;


   procedure Test_Line_Split_Active_Buffer_And_Persistence_Boundaries
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

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "GammaDelta");
      Set_Caret (S, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, "Gamma" & ASCII.LF & "Delta",
         "split mutates only active buffer B");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "active buffer split creates one active-buffer undo entry");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "inactive buffer A remains unchanged by buffer B split");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "inactive buffer A does not inherit buffer B split undo entry");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "buffer A split operates independently after switch");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text
        (S, "Gamma" & ASCII.LF & "Delta",
         "switching back preserves buffer B split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "GammaDelta",
         "undo in buffer B affects only buffer B split entry");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "buffer B undo must not mutate buffer A split text");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "split and undo must not activate another buffer");

      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Editor.Commands.Is_Available (Availability),
              "split availability should be available with active buffer and caret");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "availability must not mutate buffer text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "availability must not move caret");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "availability must not mutate undo/redo stacks");

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
         "workspace persistence must exclude Line Split transient state/settings");
   end Test_Line_Split_Active_Buffer_And_Persistence_Boundaries;


   procedure Test_Line_Split_Workflow_Position_And_Boundary_Matrices
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
             "position matrix line start");
      Check ("AlphaBeta", 5, "Alpha" & ASCII.LF & "Beta", 1,
             "position matrix middle");
      Check ("Alpha", 5, "Alpha" & ASCII.LF, 1,
             "position matrix line end");
      Check ("  Alpha", 2, "  " & ASCII.LF & "Alpha", 1,
             "position matrix inside leading spaces");
      Check ("Alpha  Beta", 7, "Alpha  " & ASCII.LF & "Beta", 1,
             "position matrix trailing spaces before suffix");
      Check (ASCII.HT & "AlphaBeta", 6,
             ASCII.HT & "Alpha" & ASCII.LF & "Beta", 1,
             "position matrix tab-leading text");
      Check ("   ", 3, "   " & ASCII.LF, 1,
             "whitespace-only line end");
      Check ("", 0, String'(1 => ASCII.LF), 1,
             "empty buffer frozen as two-empty-lines boundary");
      Check ("A" & ASCII.LF & "BC" & ASCII.LF & "D", 4,
             "A" & ASCII.LF & "B" & ASCII.LF & "C" & ASCII.LF & "D", 2,
             "middle logical line split only");
      Check ("A" & ASCII.LF & "B" & ASCII.LF & "C", 2,
             "A" & ASCII.LF & ASCII.LF & "B" & ASCII.LF & "C", 2,
             "middle line start split");
      Check ("A" & ASCII.LF & "B" & ASCII.LF & "C", 3,
             "A" & ASCII.LF & "B" & ASCII.LF & ASCII.LF & "C", 2,
             "middle line end split before boundary");
      Check ("A" & ASCII.LF & "B", 3,
             "A" & ASCII.LF & "B" & ASCII.LF, 2,
             "EOF split appends one canonical boundary");
   end Test_Line_Split_Workflow_Position_And_Boundary_Matrices;


   procedure Test_Line_Split_Undo_Redo_Dirty_Find_Clipboard_Navigation_Render
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
         "split selection/find/clipboard/navigation coherent result");
      Assert (S.Active_Find_Query = To_Unbounded_String ("AlphaBeta"),
              "split must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Alpha-Beta"),
              "split must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "split must stale active Find ranges through text edit hook");

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "render snapshot must be side-effect-free after split");
      Assert (R.Primary_Caret_Row = 1 and then R.Primary_Caret_Col = 0,
              "render snapshot exposes normalized post-split caret");
      Assert (R.Selection_Count = 0,
              "render snapshot must not expose stale selection");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "copy after cleared split selection must preserve clipboard");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "AlphaBeta" & ASCII.LF & "Gamma",
         "undo restores exact pre-split text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "undo exposes one redo entry");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "redo restores exact post-split text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Before_Text := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      Before_Dirty := Editor.State.Is_Dirty (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer) + 40));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Message_Text (S) = "Could not split line",
              "failed injected-caret split must report deterministic failure");
      Assert_Buffer_Text (S, To_String (Before_Text),
                          "failed split preserves text");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "failed split preserves dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "failed split preserves undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "failed split preserves redo stack");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "failed split preserves clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "failed split preserves navigation history");

      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "successful split after undo clears redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Message_Text (S) = "No edits to redo",
              "redo after successful split reports empty redo stack");
   end Test_Line_Split_Undo_Redo_Dirty_Find_Clipboard_Navigation_Render;


   procedure Test_Line_Split_Mixed_Command_Coexistence_Workflows
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
                          "split before join exact text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta Gamma",
                          "join after split follows separate join separator policy");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
                          "undo join restores split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "AlphaBeta" & ASCII.LF & "Gamma",
                          "undo split restores original text");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Top" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 3)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "MidTail" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom",
         "duplicate-line setup exact text");
      Set_Caret (S, Cursor_Index (Editor.Navigation.Index_For_Line_Column (S, 1, 3)));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "Mid" & ASCII.LF & "Tail" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom",
         "split after duplicate uses current logical line only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Move_Down);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "Mid" & ASCII.LF & "MidTail" & ASCII.LF & "Tail" & ASCII.LF & "Bottom",
         "move-down after split uses post-split current line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Top" & ASCII.LF & "MidTail" & ASCII.LF & "MidTail" & ASCII.LF & "Bottom",
         "undo mixed line-edit/split chain exact text");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "  AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 2);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "  " & ASCII.LF & "AlphaBeta",
                          "split inside indentation preserves sides exactly");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Assert_Buffer_Text (S, "  " & ASCII.LF & "  AlphaBeta",
                          "indent after split affects caret line only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Assert_Buffer_Text (S, "  " & ASCII.LF & "AlphaBeta",
                          "outdent after split leaves unindented caret line unchanged");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "-- AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Set_Caret (S, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "-- " & ASCII.LF & "AlphaBeta",
                          "split treats comment marker as plain text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Assert_Buffer_Text (S, "-- " & ASCII.LF & "-- AlphaBeta",
                          "toggle comment after split owns comment marker behavior");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Uncomment_Line);
      Assert_Buffer_Text (S, "-- " & ASCII.LF & "AlphaBeta",
                          "uncomment after split does not infer marker across boundary");
   end Test_Line_Split_Mixed_Command_Coexistence_Workflows;


   procedure Test_Line_Split_Active_Buffer_Routes_Features_And_Persistence
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
                 "non-goal Line Split command must not be exposed: " & Name);
      end Assert_Not_Exposed;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "GammaDelta");
      Set_Caret (S, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "Gamma" & ASCII.LF & "Delta",
                          "split mutates active buffer B only");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text (S, "AlphaBeta",
                          "inactive buffer A stays unchanged after B split");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "inactive buffer A has no inherited split undo entry");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta",
                          "buffer A split is independent");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text (S, "Gamma" & ASCII.LF & "Delta",
                          "buffer B retains its own split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "GammaDelta",
                          "undo in buffer B affects only buffer B");

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
              "command palette projects exactly one split-at-caret command");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "command palette projection must not split text");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Editor.Commands.Is_Available (Availability),
              "split availability available with active buffer/caret");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "availability must not mutate text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "availability must not move caret");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "availability must not mutate history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "Feature" & ASCII.LF & "AlphaBeta" & ASCII.LF & "Tail",
                          "feature-populated split exact text");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Feature"),
              "split does not mutate Find query in feature-populated state");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("ReplaceSeed"),
              "split does not mutate Replace text in feature-populated state");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("FEATURE-CLIP"),
              "split does not mutate clipboard in feature-populated state");

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
         "workspace persistence must exclude Line Split transient state/settings");

      Assert_Not_Exposed ("edit.line.split-selection");
      Assert_Not_Exposed ("edit.line.split-all");
      Assert_Not_Exposed ("edit.line.split-paragraph");
      Assert_Not_Exposed ("edit.paragraph.reflow");
      Assert_Not_Exposed ("edit.split.smart");
      Assert_Not_Exposed ("edit.split.language-aware");
      Assert_Not_Exposed ("edit.newline.auto-indent");
      Assert_Not_Exposed ("edit.newline.smart");
   end Test_Line_Split_Active_Buffer_Routes_Features_And_Persistence;


   procedure Test_Completeness_Selection_Caret_Only_And_Followups
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
             "selection before caret");
      Check ("AlphaBeta", 9, 5,
             "Alpha" & ASCII.LF & "Beta",
             "reversed selection after caret");
      Check ("AlphaBeta", 2, 8,
             "AlphaBet" & ASCII.LF & "a",
             "forward selection ending at caret");
      Check ("AlphaBeta", 8, 2,
             "Al" & ASCII.LF & "phaBeta",
             "backward selection ending at caret");
      Check ("One" & ASCII.LF & "AlphaBeta" & ASCII.LF & "Two",
             0,
             9,
             "One" & ASCII.LF & "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Two",
             "multi-line selection still splits caret line only");

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
                          "current-word selection does not replace selected word");
      Assert (not Editor.Selection.Has_Selection (S),
              "current-word selection is cleared by successful split mutation");
   end Test_Completeness_Selection_Caret_Only_And_Followups;


   procedure Test_Completeness_No_Buffer_No_Caret_And_Routed_Input
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
              "no-active-buffer availability is deterministic");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (Message_Text (S) = "No active buffer.",
              "no-active-buffer split reports one canonical message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0
              and then Natural (Editor.History.Redo_Stack.Length) = 0,
              "no-active-buffer split mutates no history");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "no-active-buffer split does not touch clipboard");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Editor.State.Set_Dirty (S, False);
      S.Carets.Clear;
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No caret location",
              "no-caret availability is deterministic");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, "AlphaBeta",
                          "no-caret split preserves buffer text");
      Assert (Message_Text (S) = "No caret location",
              "no-caret split reports one canonical message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0
              and then Natural (Editor.History.Redo_Stack.Length) = 0,
              "no-caret split mutates no history");
      Assert (not Editor.State.Is_Dirty (S),
              "no-caret split does not mark buffer dirty");

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
              "routed keybinding must use canonical Executor split path");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "routed keybinding split creates one undo entry");
      Assert (Message_Text (After) = "Split line",
              "routed keybinding emits canonical split message");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Completeness_No_Buffer_No_Caret_And_Routed_Input;


   procedure Test_Completeness_Read_Only_And_Persistence_Surfaces
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
                          "render snapshot must not repair stale caret by splitting");
      Assert (R.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot length derives from unchanged canonical buffer");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 0
         and then Natural (S.Carets (S.Carets.First_Index).Pos) =
           Text_Buffer.Length (S.Buffer) + 25,
         "render snapshot must not repair stale selection endpoints before split command");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "render snapshot must not mutate clipboard");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "render snapshot must not mutate history");

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Filtered_Commands (Candidates);
      Assert (Candidates.Length > 0,
              "command palette projection returns command candidates");
      Assert_Buffer_Text (S, Before_Text,
                          "command palette projection must not split or repair text");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Alpha")
              and then S.Active_Replace_Text = To_Unbounded_String ("Omega")
              and then not S.Active_Find_Stale,
              "read-only projections must not mutate Find/Replace state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Assert_Buffer_Text (S, Before_Text,
                          "stale-caret split failure preserves text");
      Assert (Message_Text (S) = "Could not split line",
              "stale-caret split failure emits deterministic one-message failure");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "stale-caret split failure preserves history");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "stale-caret split failure preserves clipboard");

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
         "persistence summary excludes split transient state after failure");
   end Test_Completeness_Read_Only_And_Persistence_Surfaces;


procedure Test_Line_Split_Canonical_Behavior_And_State_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      R              : Editor.Render_Model.Render_Snapshot;
      Workspace_Snap : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Before_Back    : Natural := 0;
      Before_Fwd     : Natural := 0;
      Before_Clip    : constant Unbounded_String := To_Unbounded_String ("CLIP");
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
         "split must insert exactly one canonical boundary at the caret");
      Assert_Caret_Row_Col (S, 1, 0,
                            "split caret must normalize to new line start");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful split must clear the stale active selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "split must create exactly one canonical undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "split must not create custom redo state");
      Assert (Editor.State.Is_Dirty (S),
              "split must update dirty state through canonical edit policy");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Alpha"),
              "split must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Omega"),
              "split must not mutate Replace text");
      Assert (S.Active_Find_Stale,
              "split must use canonical Find/Replace invalidation");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "split must not read or mutate Clipboard state");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "split must not record Navigation History");
      Assert (Message_Text (S) = "Split line",
              "split must emit the canonical one primary message");

      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert_Buffer_Text
        (S,
         "  -- Alph" & ASCII.LF & "aBeta" & ASCII.LF & "Tail",
         "render snapshot must be read-only over canonical buffer text");
      Assert (R.Primary_Caret_Row = 1 and then R.Primary_Caret_Col = 0,
              "render caret must derive from canonical caret state only");
      Assert (R.Selection_Count = 0,
              "render snapshot must not expose stale split selection state");

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
         "workspace persistence must exclude canonical and removed Line Split state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "  -- AlphaBeta" & ASCII.LF & "Tail",
                          "undo restores captured before text without replaying split");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S,
         "  -- Alph" & ASCII.LF & "aBeta" & ASCII.LF & "Tail",
         "redo restores captured after text without recomputing split policy");
   end Test_Line_Split_Canonical_Behavior_And_State_Boundaries;


   procedure Test_Line_Split_Failure_Read_Only_And_Ordinary_Newline_Separation
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
              "canonical Line Split availability should be available before split");
      Assert_Buffer_Text (S, To_String (Before_Text),
                          "availability must not mutate text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "availability must not mutate Undo/Redo stacks");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Insert_Newline);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta",
                          "ordinary Insert Newline remains separate but uses canonical text edit semantics");
      Assert (Message_Text (S) /= "Split line",
              "ordinary newline insertion must not report the Line Split command message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "ordinary newline insertion is one normal edit entry");

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
                          "failed split must preserve buffer text");
      Assert (Message_Text (S) = "Could not split line",
              "failed split must emit canonical failure message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "failed split must not mutate history stacks");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "failed split must not mutate Clipboard state");
      Assert (not Editor.State.Is_Dirty (S),
              "failed split must not dirty the buffer");
      Assert (S.Active_Find_Query = Null_Unbounded_String
              and then S.Active_Replace_Text = Null_Unbounded_String,
              "failed split must not synthesize Find/Replace state");
   end Test_Line_Split_Failure_Read_Only_And_Ordinary_Newline_Separation;




   procedure Test_Word_Delete_Command_Descriptors_And_Routes
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
         "previous-word delete stable name mismatch");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Word_Delete_Next) =
         "edit.word.delete-next",
         "next-word delete stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Word_Delete_Previous).Category =
         Editor.Commands.Edit_Category,
         "previous-word delete must be an Edit command");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Word_Delete_Next).Visibility =
         Editor.Commands.Palette_Command,
         "next-word delete must be palette visible");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Word_Delete_Previous)
         and then Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Word_Delete_Next),
         "word delete commands must be bindable");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.word.delete-previous", Found);
      Assert (Found and then Id = Editor.Commands.Command_Word_Delete_Previous,
              "previous-word stable name lookup mismatch");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.word.delete-next", Found);
      Assert (Found and then Id = Editor.Commands.Command_Word_Delete_Next,
              "next-word stable name lookup mismatch");

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
                          "Input_Bridge word delete must route through Executor");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "routed word delete must create one undo entry");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Word_Delete_Command_Descriptors_And_Routes;

   procedure Test_Delete_Previous_Word_Boundaries_Selection_And_Undo
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
                          "delete-previous must delete the preceding word span");
      Assert (Natural (S.Carets (S.Carets.First_Index).Pos) = 8,
              "delete-previous caret must move to deleted range start");
      Assert (Message_Text (S) = "Deleted previous word",
              "delete-previous success message mismatch");
      Assert (Editor.State.Is_Dirty (S),
              "delete-previous must dirty changed clean buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "delete-previous must create one undo entry");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "delete-previous must not mutate clipboard");
      Assert_Navigation_Counts (S, 0, 0,
                                "delete-previous must not record navigation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha   Beta",
                          "undo after delete-previous must restore exact text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha   ",
                          "redo after delete-previous must restore edited text");

      Editor.State.Load_Text (S, "Alpha   Beta");
      Set_Caret (S, 8);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Beta",
                          "delete-previous after whitespace must delete whitespace plus prior word");

      Editor.State.Load_Text (S, "Alpha...Beta");
      Set_Caret (S, 8);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "AlphaBeta",
                          "delete-previous must delete punctuation spans as plain text");

      Editor.State.Load_Text (S, "Alpha_Beta123");
      Set_Caret (S, 13);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "",
                          "delete-previous word class must include underscore and digits");

      Editor.State.Load_Text (S, "One" & ASCII.LF & "Two");
      Set_Caret (S, 4);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Two",
                          "delete-previous must treat line boundary as whitespace");

      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Primary_Selection (S, 0, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, " Beta",
                          "delete-previous must operate at caret, not consume selection");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful delete-previous must collapse selection");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Message_Text (S) = "Nothing to delete",
              "delete-previous buffer-start no-op message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "delete-previous no-op must preserve redo stack");
   end Test_Delete_Previous_Word_Boundaries_Selection_And_Undo;

   procedure Test_Delete_Next_Word_Boundaries_No_Ops_And_Persistence
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
                          "delete-next must delete the following word span");
      Assert (Natural (S.Carets (S.Carets.First_Index).Pos) = 0,
              "delete-next caret must remain at deletion start");
      Assert (Message_Text (S) = "Deleted next word",
              "delete-next success message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "delete-next must create one undo entry");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "delete-next must not mutate clipboard");

      Editor.State.Load_Text (S, "Alpha   Beta");
      Set_Caret (S, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha",
                          "delete-next after whitespace must delete whitespace plus next word");

      Editor.State.Load_Text (S, "...Alpha");
      Set_Caret (S, 0);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha",
                          "delete-next must delete punctuation spans as plain text");

      Editor.State.Load_Text (S, "Alpha_Beta123");
      Set_Caret (S, 0);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "",
                          "delete-next word class must include underscore and digits");

      Editor.State.Load_Text (S, "One" & ASCII.LF & "Two");
      Set_Caret (S, 3);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "One",
                          "delete-next must treat line boundary as whitespace");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Count := Natural (Editor.History.Redo_Stack.Length);
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert (Message_Text (S) = "Nothing to delete",
              "delete-next buffer-end no-op message mismatch");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Count,
              "delete-next no-op must preserve redo stack");

      S.Carets.Clear;
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No caret location",
              "no-caret availability must be deterministic");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert (Message_Text (S) = "No caret location",
              "no-caret execution message mismatch");

      Editor.State.Init (No_Buffer);
      Avail := Editor.Executor.Command_Availability
        (No_Buffer, Editor.Commands.Command_Word_Delete_Previous);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No active buffer.",
              "no-active-buffer availability must be deterministic");
      Editor.Executor.Execute_Command
        (No_Buffer, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "no-active-buffer execution message mismatch");

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
         "workspace persistence must exclude Word Delete transient state");
   end Test_Delete_Next_Word_Boundaries_No_Ops_And_Persistence;


   procedure Test_Delete_Previous_Word_Reliability_Matrix
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
                       "previous deletes simple trailing word");
      Expect_Previous ("Alpha Beta", 10, "Alpha ", 6,
                       "previous deletes trailing word after one space");
      Expect_Previous ("Alpha   Beta", 13, "Alpha   ", 8,
                       "previous preserves multiple spaces before trailing word");
      Expect_Previous ("Alpha   Beta", 8, "Beta", 0,
                       "previous deletes whitespace run plus prior word");
      Expect_Previous ("Alpha_Beta", 10, "", 0,
                       "previous treats underscore as word");
      Expect_Previous ("Alpha123", 8, "", 0,
                       "previous treats digits as word");
      Expect_Previous ("Alpha.", 6, "Alpha", 5,
                       "previous deletes single punctuation");
      Expect_Previous ("Alpha...", 8, "Alpha", 5,
                       "previous deletes punctuation run");
      Expect_Previous ("Al" & String'(1 => ASCII.HT) & "pha", 3,
                       "pha", 0,
                       "previous treats tab as whitespace plus prior word");
      Expect_Previous ("Al" & Character'Val (16#C3#) & Character'Val (16#A9#) & "pha", 3,
                       "Alpha", 2,
                       "previous treats non-ASCII bytes as other text");
      Expect_Previous ("Alpha", 2, "pha", 0,
                       "previous inside word deletes prefix span");
      Expect_Previous ("Alpha  " & "  Beta", 7, "  Beta", 0,
                       "previous inside whitespace run is deterministic");
      Expect_Previous ("Alpha.." & "..Beta", 7, "Alpha..Beta", 5,
                       "previous inside punctuation run is deterministic");
      Expect_Previous ("Alpha" & ASCII.LF & "Beta", 6, "Beta", 0,
                       "previous crosses canonical line boundary as whitespace");
      Expect_Previous ("Alpha" & ASCII.LF & ASCII.LF & "Beta", 7, "Beta", 0,
                       "previous crosses blank line boundary run as whitespace");

      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, 0);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Alpha",
                          "previous at buffer start must no-op");
      Assert (Message_Text (S) = "Nothing to delete",
              "previous no-op message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "previous no-op must not create undo");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "previous matrix must not mutate clipboard");
   end Test_Delete_Previous_Word_Reliability_Matrix;

   procedure Test_Delete_Next_Word_Reliability_Matrix
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
                   "next deletes simple leading word");
      Expect_Next ("Alpha Beta", 0, " Beta", 0,
                   "next preserves following separator after first word");
      Expect_Next ("Alpha   Beta", 5, "Alpha", 5,
                   "next deletes whitespace run plus following word");
      Expect_Next ("Alpha_Beta", 0, "", 0,
                   "next treats underscore as word");
      Expect_Next ("Alpha123", 0, "", 0,
                   "next treats digits as word");
      Expect_Next ("...Alpha", 0, "Alpha", 0,
                   "next deletes punctuation run");
      Expect_Next (", Alpha", 0, " Alpha", 0,
                   "next deletes single punctuation");
      Expect_Next ("Al" & String'(1 => ASCII.HT) & "pha", 2, "Al", 2,
                   "next treats tab as whitespace plus following word");
      Expect_Next ("Alpha", 2, "Al", 2,
                   "next inside word deletes suffix span");
      Expect_Next ("Alpha  " & "  Beta", 7, "Alpha  ", 7,
                   "next inside whitespace run is deterministic");
      Expect_Next ("Alpha.." & "..Beta", 7, "Alpha..Beta", 7,
                   "next inside punctuation run is deterministic");
      Expect_Next ("Alpha" & ASCII.LF & "Beta", 5, "Alpha", 5,
                   "next crosses canonical line boundary as whitespace");
      Expect_Next ("Alpha" & ASCII.LF & ASCII.LF & "Beta", 5, "Alpha", 5,
                   "next crosses blank line boundary run as whitespace");

      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, 5);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha",
                          "next at buffer end must no-op");
      Assert (Message_Text (S) = "Nothing to delete",
              "next no-op message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "next no-op must not create undo");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "next matrix must not mutate clipboard");
   end Test_Delete_Next_Word_Reliability_Matrix;

   procedure Test_Word_Delete_State_Integration_And_Read_Only_Boundaries
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
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Beta");
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
              "word delete availability must remain available with buffer and caret");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert (Editor.Commands.Is_Available (Avail),
              "next word delete availability must remain available with buffer and caret");
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot length must derive from canonical buffer text");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text),
              "render/availability must not mutate buffer text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "render/availability must not move caret");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "render/availability must not mutate undo/redo stacks");
      Assert (Editor.State.Is_Dirty (S) = Before_Dirty,
              "render/availability must not mutate dirty state");
      Assert (S.Active_Find_Stale = Before_Stale
              and then To_String (S.Active_Find_Query) = "Beta"
              and then To_String (S.Active_Replace_Text) = "REPL",
              "render/availability must not mutate Find/Replace state");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "render/availability must not mutate navigation history");

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha ",
                          "delete-next must remove exact active Find match text");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "text-changing word delete must invalidate Find ranges");
      Assert (To_String (S.Active_Find_Query) = "Beta"
              and then To_String (S.Active_Replace_Text) = "REPL"
              and then S.Active_Replace_Prompt,
              "word delete must preserve Find query and Replace text");
      Assert (Editor.Clipboard.Has_Text
              and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
              "word delete must not mutate clipboard");
      Assert_Navigation_Counts (S, 0, 0,
                                "word delete must not record navigation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "undo must restore exact pre-delete text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "undo after word delete must make redo available");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Message_Text (S) = "Nothing to delete",
              "no-op after undo must report Nothing to delete");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "no-op after undo must preserve redo stack");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "successful word delete after undo must clear redo stack");
   end Test_Word_Delete_State_Integration_And_Read_Only_Boundaries;

   procedure Test_Word_Delete_Current_Line_Coexistence_And_Persistence
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
                          "split precondition must produce canonical line boundary");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Beta",
                          "word delete after split must use buffer text, not Line Join");
      Assert (Message_Text (S) = "Deleted previous word",
              "word delete after split message mismatch");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta",
                          "undo after mixed split/delete must restore split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Beta",
                          "redo after mixed split/delete must restore delete result");

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
              "word delete after join must still be a word-delete command");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 2,
              "mixed join/delete sequence must keep one undo entry per mutation");

      Snap := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snap));
      Assert
        (Index (Summary, "word delete") = 0
         and then Index (Summary, "deleted word") = 0
         and then Index (Summary, "last word") = 0
         and then Index (Summary, "word-boundary") = 0,
         "workspace persistence must exclude Word Delete transient state");
   end Test_Word_Delete_Current_Line_Coexistence_And_Persistence;



   procedure Test_Word_Delete_Boundary_Transform_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha|", "|", "Alpha",
         "previous boundary simple word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha Beta|", "Alpha |", "Beta",
         "previous boundary trailing word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha   Beta|", "Alpha   |", "Beta",
         "previous boundary preserves whitespace before word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha   |Beta", "|Beta", "Alpha   ",
         "previous boundary deletes whitespace plus prior word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha_Beta|", "|", "Alpha_Beta",
         "previous boundary underscore word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha123|", "|", "Alpha123",
         "previous boundary digit word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha.|", "Alpha|", ".",
         "previous boundary punctuation");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha...|", "Alpha|", "...",
         "previous boundary punctuation run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha, Beta|", "Alpha, |", "Beta",
         "previous boundary mixed punctuation and word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Al|pha", "|pha", "Al",
         "previous boundary inside word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha  |  Beta", "|  Beta", "Alpha  ",
         "previous boundary inside whitespace run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha..|..Beta", "Alpha|..Beta", "..",
         "previous boundary inside punctuation run");

      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|Alpha", "|", "Alpha",
         "next boundary simple word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|Alpha Beta", "| Beta", "Alpha",
         "next boundary leading word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha |  Beta", "Alpha |", "  Beta",
         "next boundary whitespace plus word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|Alpha_Beta", "|", "Alpha_Beta",
         "next boundary underscore word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|Alpha123", "|", "Alpha123",
         "next boundary digit word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|...Alpha", "|Alpha", "...",
         "next boundary punctuation run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|, Alpha", "| Alpha", ",",
         "next boundary punctuation");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Al|pha", "Al|", "pha",
         "next boundary inside word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha  |  Beta", "Alpha  |", "  Beta",
         "next boundary inside whitespace run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha..|..Beta", "Alpha..|Beta", "..",
         "next boundary inside punctuation run");

      Assert_Word_Delete_No_Op
        (Word_Delete_Test_Previous, "|Alpha",
         "previous no-op at buffer start");
      Assert_Word_Delete_No_Op
        (Word_Delete_Test_Next, "Alpha|",
         "next no-op at buffer end");
   end Test_Word_Delete_Boundary_Transform_Workflows;

   procedure Test_Word_Delete_Cross_Line_Selection_Find_Clipboard
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
         "previous crosses one line boundary as whitespace");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha|" & ASCII.LF & "Beta", "Alpha|",
         String'(1 => ASCII.LF) & "Beta",
         "next crosses one line boundary as whitespace");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha" & ASCII.LF & ASCII.LF & "|Beta", "|Beta",
         "Alpha" & ASCII.LF & ASCII.LF,
         "previous crosses blank line boundary run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha|" & ASCII.LF & ASCII.LF & "Beta", "Alpha|",
         String'(1 => ASCII.LF) & ASCII.LF & "Beta",
         "next crosses blank line boundary run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha" & ASCII.LF & "  |Beta", "|Beta",
         "Alpha" & ASCII.LF & "  ",
         "previous treats indentation as plain whitespace");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha|" & ASCII.LF & "  Beta", "Alpha|",
         String'(1 => ASCII.LF) & "  Beta",
         "next treats indentation as plain whitespace");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (Before_Clip);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Editor.State.Set_Dirty (S, False);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Beta");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "REPL");
      Set_Primary_Selection (S, 0, 5);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha  Gamma",
                          "delete-next removes exact Find match word");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "text-changing Word Delete must invalidate computed Find ranges");
      Assert (To_String (S.Active_Find_Query) = "Beta"
              and then To_String (S.Active_Replace_Text) = "REPL"
              and then S.Active_Replace_Prompt,
              "Word Delete must preserve Find query and Replace text");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful Word Delete must collapse active selection");
      Assert (Editor.Clipboard.Has_Text
              and then Editor.Clipboard.Get_Text = Before_Clip,
              "Word Delete must not copy deleted word into Clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Word Delete must not record navigation history");
      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert (R.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot after Word Delete must match canonical buffer length");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta Gamma",
                          "undo restores exact Find workflow text");
      Editor.Render_Model.Build_Render_Snapshot (S, R);
      Assert (R.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot after undo must match canonical buffer length");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha  Gamma",
                          "redo restores exact Find workflow text");

      Set_Caret (S, 0);
      S.Active_Find_Stale := False;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (not S.Active_Find_Stale,
              "no-op Word Delete must not invalidate Find/Replace state");
   end Test_Word_Delete_Cross_Line_Selection_Find_Clipboard;

   procedure Test_Word_Delete_Undo_Redo_Dirty_And_Current_Line_Coexistence
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
                          "dirty matrix delete-previous text");
      Assert (Editor.State.Is_Dirty (S),
              "text-changing delete-previous must dirty clean buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "delete-previous must create one undo entry");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "undo after delete-previous restores baseline text");
      Assert (not Editor.State.Is_Dirty (S),
              "undo to saved baseline must clear dirty state");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha ",
                          "redo after delete-previous restores edited text");
      Assert (Editor.State.Is_Dirty (S),
              "redo to edited text must restore dirty state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "no-op delete-previous after undo preserves redo stack");
      Set_Caret (S, Cursor_Index (Text_Buffer.Length (S.Buffer)));
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "successful delete-previous after undo clears redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Message_Text (S) = "No edits to redo",
              "redo after successful Word Delete invalidation must be unavailable");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "AlphaBeta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Beta",
                          "split then delete-previous must delete by canonical text only");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "Beta",
                          "undo mixed split/delete restores split text");

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
              "join/delete sequence must keep one undo entry per mutation");

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
              "indent/delete mixed workflow must stay in Word Delete command path");

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
              "comment/delete mixed workflow must stay in Word Delete command path");
   end Test_Word_Delete_Undo_Redo_Dirty_And_Current_Line_Coexistence;

   procedure Test_Word_Delete_Active_Buffer_Routes_Features_And_Persistence
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
                          "active-buffer A delete text");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Buffer_Text (S, "Gamma Delta",
                          "active-buffer B must be isolated from A delete");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, "Gamma ",
                          "active-buffer B independent delete text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Gamma Delta",
                          "undo in B affects only B");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Buffer_Text (S, "Alpha ",
                          "returning to A preserves A delete result");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "undo in A affects only A");

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
              "availability check must expose Word Delete with active buffer/caret");
      declare
         Candidates : Editor.Commands.Command_Descriptor_Vectors.Vector;
      begin
         Editor.Command_Palette.Reset;
         Editor.Command_Palette.Filtered_Commands (Candidates);
         Assert (Candidates.Length > 0,
                 "Command Palette projection must return candidates");
      end;
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Before_Text)
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo
              and then Editor.State.Is_Dirty (S) = Before_Dirty,
              "availability/palette projection must be side-effect-free");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "availability/palette must not mutate navigation history");

      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Word_Delete_Next);
      Set_Caret (S, 0);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      declare
         After : constant Editor.State.State_Type :=
           Editor.Input_Bridge.Get_State_For_Test;
      begin
         Assert_Buffer_Text (After, " Beta",
                             "Input_Bridge keybinding must route delete-next through Executor");
         Assert (Message_Text (After) = "Deleted next word",
                 "routed delete-next message mismatch");
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
         "workspace persistence must exclude Word Delete transient state and policy");
   end Test_Word_Delete_Active_Buffer_Routes_Features_And_Persistence;


   procedure Test_Word_Delete_Canonical_Surface_Cleanup
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
      Path           : constant String := "/tmp/editor-canonical-word-delete-keybindings";
      File           : Ada.Text_IO.File_Type;
      Config         : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status         : Editor.Keybinding_Config.Keybinding_Config_Status;
      Chord          : Editor.Keybindings.Key_Chord;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.word.delete-previous", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Word_Delete_Previous,
         "previous Word Delete command must resolve through canonical stable name");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.word.delete-next", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Word_Delete_Next,
         "next Word Delete command must resolve through canonical stable name");

      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            C    : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
            Name : constant String := Editor.Commands.Stable_Command_Name (C);
         begin
            if C = Editor.Commands.Command_Word_Delete_Previous then
               Previous_Count := Previous_Count + 1;
               Assert (Name = "edit.word.delete-previous",
                       "previous Word Delete registry stable name mismatch");
            elsif C = Editor.Commands.Command_Word_Delete_Next then
               Next_Count := Next_Count + 1;
               Assert (Name = "edit.word.delete-next",
                       "next Word Delete registry stable name mismatch");
            else
               Assert
                 (Name /= "edit.word.delete-previous"
                  and then Name /= "edit.word.delete-next",
                  "registry must not expose duplicate Word Delete command names");
            end if;
         end;
      end loop;
      Assert (Previous_Count = 1 and then Next_Count = 1,
              "registry must contain exactly the canonical Word Delete descriptor pair");

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Filtered_Commands (Candidates);
      for C of Candidates loop
         if C.Id = Editor.Commands.Command_Word_Delete_Previous then
            Palette_Prev := Palette_Prev + 1;
            Assert (To_String (C.Name) = "Delete Previous Word",
                    "palette previous Word Delete label mismatch");
         elsif C.Id = Editor.Commands.Command_Word_Delete_Next then
            Palette_Next := Palette_Next + 1;
            Assert (To_String (C.Name) = "Delete Next Word",
                    "palette next Word Delete label mismatch");
         end if;
      end loop;
      Assert (Palette_Prev = 1 and then Palette_Next = 1,
              "Command Palette must expose exactly the canonical Word Delete pair");

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
                       "default previous Word Delete keybinding must target canonical name");
            elsif Command = Editor.Commands.Command_Word_Delete_Next then
               Assert (Name = "edit.word.delete-next",
                       "default next Word Delete keybinding must target canonical name");
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
              "canonical Word Delete keybinding names must load cleanly");
      Chord := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Word_Delete_Previous, Found);
      Assert
        (Found and then Editor.Keybindings.Format_Chord (Chord) = "Ctrl+Alt+Backspace",
         "canonical previous Word Delete keybinding must remain loadable");
      Chord := Editor.Keybinding_Config.Chord_For
        (Config, Editor.Commands.Command_Word_Delete_Next, Found);
      Assert
        (Found and then Editor.Keybindings.Format_Chord (Chord) = "Ctrl+Alt+Delete",
         "canonical next Word Delete keybinding must remain loadable");

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
   end Test_Word_Delete_Canonical_Surface_Cleanup;


   procedure Test_Word_Delete_Canonical_Routes_And_State_Boundaries
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
                          "canonical previous Word Delete id must use the only previous-word delete implementation path");
      Assert (Message_Text (S) = "Deleted previous word",
              "canonical previous Word Delete id must emit canonical Word Delete message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1
              and then Natural (Editor.History.Redo_Stack.Length) = 0,
              "canonical previous Word Delete id must use canonical undo capture");
      Assert (Editor.State.Is_Dirty (S),
              "canonical previous Word Delete id must use canonical dirty policy");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Word Delete must not mutate Clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Word Delete must not record Navigation History");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot must derive from canonical post-delete buffer text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta",
                          "undo for canonical Word Delete must restore captured Before_Text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha ",
                          "redo for canonical Word Delete must restore captured After_Text without re-running word logic");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, Cursor_Index (0));
      Editor.State.Set_Dirty (S, False);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, " Beta",
                          "canonical next Word Delete id must use the only next-word delete implementation path");
      Assert (Message_Text (S) = "Deleted next word",
              "canonical next Word Delete id must emit canonical Word Delete message");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1
              and then Natural (Editor.History.Redo_Stack.Length) = 0,
              "canonical next Word Delete id must use canonical undo capture");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "canonical next Word Delete id must not mutate Clipboard text");

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
         "canonical Word Delete id must remain a valid keybinding target");
      Assert
        (Editor.Keybindings.Resolve (Chord, Resolved_Id) = Editor.Keybindings.Bound_Command
         and then Resolved_Id = Editor.Commands.Command_Word_Delete_Previous,
         "runtime keybinding resolution must expose only canonical Word Delete ids");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (After, " ",
         "Input_Bridge must dispatch canonical Word Delete keybindings through Executor");
      Assert (Message_Text (After) = "Deleted previous word",
              "canonical keybinding must emit one Word Delete message");
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
         "workspace persistence must exclude canonical and removed Word Delete state");
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Word_Delete_Canonical_Routes_And_State_Boundaries;


   procedure Test_Word_Delete_Behavior_Preservation_Smoke
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
         "preservation previous whitespace plus prior word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha...|", "Alpha|", "...",
         "preservation previous punctuation run");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha |  Beta", "Alpha |", "  Beta",
         "preservation next whitespace plus following word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "|Alpha_Beta123", "|", "Alpha_Beta123",
         "preservation next underscore and digit word");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Previous, "Alpha" & ASCII.LF & "  |Beta", "|Beta",
         "Alpha" & ASCII.LF & "  ",
         "preservation previous cross-line whitespace policy");
      Assert_Word_Delete_Transform
        (Word_Delete_Test_Next, "Alpha|" & ASCII.LF & "  Beta", "Alpha|",
         ASCII.LF & "  Beta",
         "preservation next cross-line whitespace policy");
      Assert_Word_Delete_No_Op
        (Word_Delete_Test_Previous, "|Alpha",
         "preservation previous start no-op");
      Assert_Word_Delete_No_Op
        (Word_Delete_Test_Next, "Alpha|",
         "preservation next end no-op");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta Gamma");
      Set_Primary_Selection (S, 0, 6);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Before_Clip := Editor.Clipboard.Get_Text;
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Beta");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Word_Delete_Next);
      Assert (Editor.Commands.Is_Available (Avail),
              "canonical next Word Delete availability must remain available");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "pre-delete render snapshot must be side-effect-free");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Word_Delete_Next);
      Assert_Buffer_Text (S, "Alpha  Gamma",
                          "canonical delete-next smoke text mismatch");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful Word Delete must collapse stale active selection");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "text-changing Word Delete must use canonical Find invalidation");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "canonical Word Delete must preserve Clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "canonical Word Delete must preserve Navigation History stacks");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "post-delete render snapshot must come from canonical buffer text");
   end Test_Word_Delete_Behavior_Preservation_Smoke;


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

   procedure Test_Character_Delete_Command_Descriptors_And_Routes
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
         "previous-character delete stable name mismatch");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Char_Delete_Next) =
         "edit.char.delete-next",
         "next-character delete stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Char_Delete_Previous).Category =
         Editor.Commands.Edit_Category,
         "previous-character delete must be an Edit command");
      Assert
        (Editor.Commands.Visible_In_Command_Palette
           (Editor.Commands.Command_Char_Delete_Next),
         "next-character delete must be palette visible");
      Assert
        (Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Char_Delete_Previous)
         and then Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Char_Delete_Next),
         "Character Delete commands must be bindable");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("edit.char.delete-previous", Found) =
         Editor.Commands.Command_Char_Delete_Previous and then Found,
         "previous-character stable name must resolve");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("edit.char.delete-next", Found) =
         Editor.Commands.Command_Char_Delete_Next and then Found,
         "next-character stable name must resolve");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AB");
      Set_Caret (S, 1);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text (S, "A", "next-character command must route through Executor");
      Assert (Message_Text (S) = "Deleted next character",
              "next-character routed message mismatch");
   end Test_Character_Delete_Command_Descriptors_And_Routes;

   procedure Test_Delete_Previous_Character_Boundaries_Selection_And_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha|", "Alph|",
         "delete previous at line end");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "A|lpha", "|lpha",
         "delete previous in middle of line");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha | Beta", "Alpha| Beta",
         "delete previous whitespace");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha.|", "Alpha|",
         "delete previous punctuation");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & "|Beta", "Alpha|Beta",
         "delete previous line boundary");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Previous, "|Alpha",
         "delete previous at buffer start no-op");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "ABCD");
      Set_Primary_Selection (S, 0, 4);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text (S, "ABC", "character delete must operate at caret only");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful character delete must collapse selection");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "character delete must not consume/copy selection");
   end Test_Delete_Previous_Character_Boundaries_Selection_And_Undo;

   procedure Test_Delete_Next_Character_Boundaries_No_Ops_And_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Fwd  : Natural := 0;
   begin
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "|Alpha", "|lpha",
         "delete next at line start");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Al|pha", "Al|ha",
         "delete next in middle of line");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha | Beta", "Alpha |Beta",
         "delete next whitespace");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "|.Alpha", "|Alpha",
         "delete next punctuation");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & "Beta", "Alpha|Beta",
         "delete next line boundary");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Next, "Alpha|",
         "delete next at buffer end no-op");

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
      Assert_Buffer_Text (S, "ACD", "character delete after navigation must edit active text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "character delete must preserve Navigation History stacks");
   end Test_Delete_Next_Character_Boundaries_No_Ops_And_State;


   procedure Test_Character_Delete_Completeness_Routes_State_And_Persistence
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
              "previous-character no-active-buffer availability must be deterministic");
      Editor.Executor.Execute_Command
        (No_Buffer, Editor.Commands.Command_Char_Delete_Previous);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "previous-character no-active-buffer execution message mismatch");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AB");
      S.Carets.Clear;
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Char_Delete_Next);
      Assert (not Editor.Commands.Is_Available (Avail)
              and then Editor.Commands.Unavailable_Reason (Avail) = "No caret location",
              "next-character no-caret availability must be deterministic");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert (Message_Text (S) = "No caret location",
              "next-character no-caret execution message mismatch");
      Assert_Buffer_Text (S, "AB",
                          "no-caret character delete must not mutate text");

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
              "character delete must be available for active buffer and caret");
      Assert (To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer)) = Before_Text
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret
              and then Editor.State.Is_Dirty (S) = Before_Dirty
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo
              and then Editor.Clipboard.Get_Text = Before_Clip,
              "character delete availability must be side-effect-free");

      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Char_Delete_Previous);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (After, "ACD",
         "Input_Bridge must dispatch previous-character delete through Executor");
      Assert (Message_Text (After) = "Deleted previous character",
              "Input_Bridge previous-character route message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo + 1,
              "Input_Bridge previous-character route must create one undo entry");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "routed character delete must not mutate Clipboard");

      Editor.Render_Model.Build_Render_Snapshot (After, Snap);
      Assert (Snap.Length = Text_Buffer.Length (After.Buffer),
              "render snapshot must derive from post-character-delete buffer text");

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
         "workspace persistence must exclude Character Delete transient state");

      Editor.Keybindings.Reset_To_Defaults;
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Character_Delete_Completeness_Routes_State_And_Persistence;


   procedure Test_Character_Delete_Previous_Reliability_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Redo_Count : Natural := 0;
   begin
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha|", "Alph|",
         "delete-previous ordinary end character");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "A|lpha", "|lpha",
         "delete-previous ordinary middle character");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha | Beta", "Alpha| Beta",
         "delete-previous treats space as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha" & ASCII.HT & "|Beta", "Alpha|Beta",
         "delete-previous treats tab as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha.|", "Alpha|",
         "delete-previous treats punctuation as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & "|Beta", "Alpha|Beta",
         "delete-previous removes exactly the previous line boundary");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, ASCII.LF & "|Beta", "|Beta",
         "delete-previous removes leading line boundary only");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha|" & ASCII.LF & "Beta", "Alph|" & ASCII.LF & "Beta",
         "delete-previous at line end deletes preceding character not next boundary");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & ASCII.LF & "|Beta", "Alpha" & ASCII.LF & "|Beta",
         "delete-previous before blank line removes one boundary only");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & "  |Beta", "Alpha" & ASCII.LF & " |Beta",
         "delete-previous before indented text deletes one space only");

      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Previous, "|Alpha",
         "delete-previous at buffer start no-ops");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Previous, "|",
         "delete-previous in empty buffer no-ops");

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
              "successful delete-previous after undo must clear redo stack");

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
              "no-op delete-previous after undo must preserve redo stack");
   end Test_Character_Delete_Previous_Reliability_Matrix;

   procedure Test_Character_Delete_Next_Reliability_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Redo_Count : Natural := 0;
   begin
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "|Alpha", "|lpha",
         "delete-next ordinary first character");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Al|pha", "Al|ha",
         "delete-next ordinary middle character");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha | Beta", "Alpha |Beta",
         "delete-next treats space as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.HT & "Beta", "Alpha|Beta",
         "delete-next treats tab as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "|.Alpha", "|Alpha",
         "delete-next treats punctuation as one text unit");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & "Beta", "Alpha|Beta",
         "delete-next removes exactly the following line boundary");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha" & ASCII.LF & "|Beta", "Alpha" & ASCII.LF & "|eta",
         "delete-next at line start deletes following text character");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF, "Alpha|",
         "delete-next removes trailing newline boundary only");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & ASCII.LF & "Beta", "Alpha|" & ASCII.LF & "Beta",
         "delete-next before blank line removes one boundary only");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & "  Beta", "Alpha|  Beta",
         "delete-next before whitespace-only prefix removes boundary only");

      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Next, "Alpha|",
         "delete-next at buffer end no-ops");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Next, "|",
         "delete-next in empty buffer no-ops");

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
              "successful delete-next after undo must clear redo stack");

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
              "no-op delete-next after undo must preserve redo stack");
   end Test_Character_Delete_Next_Reliability_Matrix;

   procedure Test_Character_Delete_State_Integration_And_Read_Only_Boundaries
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
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Beta");
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
         "delete-next must operate at caret, not consume selection");
      Assert (S.Carets (S.Carets.First_Index).Pos = 6,
              "delete-next caret must remain at deletion start");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful Character Delete must clear selection");
      Assert (Editor.Clipboard.Has_Text and then Editor.Clipboard.Get_Text = Before_Clip,
              "Character Delete must preserve Clipboard text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Character Delete must not record or clear Navigation History");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "text-changing Character Delete must use canonical Find invalidation");
      Assert (To_String (S.Active_Find_Query) = "Beta",
              "Character Delete must not mutate Find query text");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot must reflect post-delete active-buffer text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "text-changing Character Delete must create exactly one undo entry");

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
              "Character Delete availability must remain available with active buffer and caret");
      Assert (To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer)) = Before_Text
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret
              and then Editor.State.Is_Dirty (S) = Before_Dirty
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo
              and then Editor.Clipboard.Get_Text = Before_Clip,
              "Character Delete availability must be side-effect-free");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer)) = Before_Text
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "render snapshot must not repair or perform Character Delete");
   end Test_Character_Delete_State_Integration_And_Read_Only_Boundaries;

   procedure Test_Character_Delete_Mixed_Command_Coexistence_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S         : Editor.State.State_Type;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary   : Unbounded_String;
   begin
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Previous, "Alpha Beta|", "Alpha Bet|",
         "delete-previous remains one text unit after word-delete-capable text");
      Assert_Character_Delete_Transform
        (Character_Delete_Test_Next, "Alpha |Beta", "Alpha |eta",
         "delete-next remains one text unit before word-delete-capable text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AlphaBeta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "split then delete-previous must remove canonical boundary without invoking Line Join");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 2,
              "mixed split/delete workflow must preserve undo ordering");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "undo after split/delete must restore split text exactly");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "redo after split/delete must restore post-delete text exactly");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "join then delete-next must use resulting active-buffer text only");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "   Alpha");
      Set_Caret (S, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "Alpha",
         "indentation then delete-next must not share corruptible transient state");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Comment_Line);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "- Alpha",
         "comment then delete-next treats comment marker as plain text");

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
         "workspace persistence must exclude Character Delete reliability state");
   end Test_Character_Delete_Mixed_Command_Coexistence_And_Persistence;

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

   procedure Test_Character_Delete_Boundary_Transform_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha|", "Alph|", "a",
         "previous ordinary end transform");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "A|lpha", "|lpha", "A",
         "previous ordinary middle transform");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Previous, "|Alpha",
         "previous buffer-start no-op");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha | Beta", "Alpha| Beta", " ",
         "previous deletes exactly one space");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha" & ASCII.HT & "|Beta", "Alpha|Beta", "" & ASCII.HT,
         "previous deletes exactly one tab");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha.|", "Alpha|", ".",
         "previous deletes exactly one punctuation unit");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & "|Beta", "Alpha|Beta", "" & ASCII.LF,
         "previous deletes exactly previous line boundary");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha|" & ASCII.LF & "Beta", "Alph|" & ASCII.LF & "Beta", "a",
         "previous at line end deletes preceding character");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, ASCII.LF & "|Beta", "|Beta", "" & ASCII.LF,
         "previous removes leading boundary only");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Previous, "Alpha" & ASCII.LF & ASCII.LF & "|Beta", "Alpha" & ASCII.LF & "|Beta", "" & ASCII.LF,
         "previous before blank line removes one boundary");

      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "|Alpha", "|lpha", "A",
         "next ordinary first transform");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Al|pha", "Al|ha", "p",
         "next ordinary middle transform");
      Assert_Character_Delete_No_Op
        (Character_Delete_Test_Next, "Alpha|",
         "next buffer-end no-op");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha | Beta", "Alpha |Beta", " ",
         "next deletes exactly one space");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha|" & ASCII.HT & "Beta", "Alpha|Beta", "" & ASCII.HT,
         "next deletes exactly one tab");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "|.Alpha", "|Alpha", ".",
         "next deletes exactly one punctuation unit");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & "Beta", "Alpha|Beta", "" & ASCII.LF,
         "next deletes exactly following line boundary");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha" & ASCII.LF & "|Beta", "Alpha" & ASCII.LF & "|eta", "B",
         "next at line start deletes following character");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF, "Alpha|", "" & ASCII.LF,
         "next removes trailing newline boundary only");
      Assert_Character_Delete_Transform_Exact
        (Character_Delete_Test_Next, "Alpha|" & ASCII.LF & ASCII.LF & "Beta", "Alpha|" & ASCII.LF & "Beta", "" & ASCII.LF,
         "next before blank line removes one boundary");
   end Test_Character_Delete_Boundary_Transform_Workflows;

   procedure Test_Character_Delete_State_Find_Clipboard_Navigation_Render
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
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Beta");
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
        (S, "Alpha Bet Gamma",
         "previous delete must remove exact adjacent character after selection/find setup");
      Assert (S.Carets (S.Carets.First_Index).Pos = 9,
              "previous delete caret must move to deleted range start");
      Assert (not Editor.Selection.Has_Selection (S),
              "successful Character Delete must clear active selection");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "text-changing Character Delete must invalidate Find matches");
      Assert (To_String (S.Active_Find_Query) = "Beta",
              "Character Delete must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("BETA")
              and then S.Active_Replace_Prompt,
              "Character Delete must not mutate Replace text or visibility");
      Assert (Editor.Clipboard.Has_Text and then Editor.Clipboard.Get_Text = Before_Clip,
              "Character Delete must not mutate Clipboard");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Character Delete must preserve Navigation History stacks");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1
              and then Natural (Editor.History.Redo_Stack.Length) = 0,
              "text-changing Character Delete must create exactly one undo entry and clear redo");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot must derive from post-delete buffer text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta Gamma",
                          "undo restores pre-delete text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha Bet Gamma",
                          "redo restores post-delete text");

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
              "no-op previous delete after undo must preserve redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "See",
                          "redo after no-op previous delete must remain available");

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
              "Character Delete availability must be available with active buffer and caret");
      declare
         Candidates : Editor.Commands.Command_Descriptor_Vectors.Vector;
      begin
         Editor.Command_Palette.Reset;
         Editor.Command_Palette.Filtered_Commands (Candidates);
         Assert (Candidates.Length > 0,
                 "Command Palette projection must produce candidates");
      end;
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer)) = Before_Text
              and then S.Carets (S.Carets.First_Index).Pos = Before_Caret
              and then Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo
              and then Editor.State.Is_Dirty (S) = Before_Dirty,
              "availability/palette/render paths must be side-effect-free");
   end Test_Character_Delete_State_Find_Clipboard_Navigation_Render;

   procedure Test_Character_Delete_Mixed_Command_Coexistence_Workflows
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
         "word-delete then char-delete-previous must use resulting canonical text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha Beta");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Word_Delete_Next);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "Beta",
         "word-delete-next then char-delete-next must use resulting canonical text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "AlphaBeta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "split then delete-previous must delete boundary without invoking Line Join");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "undo in split/delete workflow restores exact split text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "redo in split/delete workflow restores exact post-delete text");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha" & ASCII.LF & "Beta");
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "join then delete-next must use resulting canonical text only");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Duplicate);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "eta" & ASCII.LF & "Beta",
         "duplicate-line then delete-next remains ordinary adjacent deletion");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "   Alpha");
      Set_Caret (S, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Decrease);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "Alpha",
         "indentation then delete-next must not share transient state");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Load_Text (S, "Alpha");
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Set_Caret (S, 0);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text
        (S, "- Alpha",
         "line-comment then delete-next treats comment marker as plain text");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "mixed workflows must not let Character Delete mutate Clipboard");
   end Test_Character_Delete_Mixed_Command_Coexistence_Workflows;

   procedure Test_Character_Delete_Active_Buffer_Routes_And_Persistence
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
                          "active-buffer A Character Delete text");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Buffer_Text (S, "Gamma",
                          "active-buffer B must be isolated from A Character Delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Assert_Buffer_Text (S, "amma",
                          "active-buffer B independent Character Delete text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Gamma",
                          "undo in B affects only B");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert_Buffer_Text (S, "Alph",
                          "returning to A preserves A Character Delete result");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha",
                          "undo in A affects only A");

      Editor.State.Init (No_Buffer);
      Editor.Executor.Execute_Command
        (No_Buffer, Editor.Commands.Command_Char_Delete_Previous);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "no-active-buffer previous delete message mismatch");
      Editor.Executor.Execute_Command
        (No_Buffer, Editor.Commands.Command_Char_Delete_Next);
      Assert (Message_Text (No_Buffer) = "No active buffer.",
              "no-active-buffer next delete message mismatch");

      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Char_Delete_Next);
      Set_Caret (S, 0);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (After, "lpha",
         "Input_Bridge keybinding must route char-delete-next through Executor");
      Assert (Message_Text (After) = "Deleted next character",
              "routed char-delete-next message mismatch");
      Editor.Keybindings.Reset_To_Defaults;

      declare
         Dummy : Editor.Commands.Command_Id;
      begin
         Dummy := Editor.Commands.Command_Id_From_Stable_Name
           ("edit.char.delete-current", Found);
         Assert (Dummy = Editor.Commands.No_Command and then not Found,
                 "non-goal delete-current command must not resolve");
         Dummy := Editor.Commands.Command_Id_From_Stable_Name
           ("edit.char.kill", Found);
         Assert (Dummy = Editor.Commands.No_Command and then not Found,
                 "non-goal char-kill command must not resolve");
         Dummy := Editor.Commands.Command_Id_From_Stable_Name
           ("selection.delete", Found);
         Assert (Found and then Dummy = Editor.Commands.Command_Selection_Delete,
                 "selection-delete command must resolve through canonical selection namespace");
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
         "workspace persistence must exclude Character Delete workflow state");
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Character_Delete_Active_Buffer_Routes_And_Persistence;


procedure Test_Character_Delete_Canonical_Routes_State_And_Persistence
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
         "default Backspace binding must route to canonical previous-character delete");
      Bind_Status := Editor.Keybindings.Resolve (Next_Chord, Resolved_Id);
      Assert
        (Bind_Status = Editor.Keybindings.Bound_Command
         and then Resolved_Id = Editor.Commands.Command_Char_Delete_Next,
         "default Delete binding must route to canonical next-character delete");

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
         "routed default Backspace must use canonical adjacent previous-character delete");
      Assert
        (Message_Text (After) = "Deleted previous character",
         "routed default Backspace message mismatch");
      Assert
        (Natural (Editor.History.Undo_Stack.Length) = 1
         and then Natural (Editor.History.Redo_Stack.Length) = 0,
         "routed default Backspace must create exactly one canonical undo entry");
      Assert
        (Editor.State.Is_Dirty (After),
         "routed default Backspace must dirty through canonical policy");
      Assert
        (not Editor.Selection.Has_Selection (After),
         "routed default Backspace must collapse selection through canonical mutation policy");
      Assert
        (Editor.Clipboard.Get_Text = Before_Clip,
         "routed default Backspace must not mutate Clipboard");
      Assert_Navigation_Counts
        (After, 0, 0,
         "routed default Backspace must not record Navigation History");

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
         "routed default Delete must use canonical adjacent next-character delete");
      Assert
        (Message_Text (After) = "Deleted next character",
         "routed default Delete message mismatch");
      Assert
        (Natural (Editor.History.Undo_Stack.Length) = 1
         and then Natural (Editor.History.Redo_Stack.Length) = 0,
         "routed default Delete must create exactly one canonical undo entry");
      Assert
        (Editor.Clipboard.Get_Text = Before_Clip,
         "routed default Delete must not mutate Clipboard");

      Editor.Executor.Execute_Command (After, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (After, "ABC",
         "undo after canonical Character Delete must restore captured Before_Text");
      Editor.Executor.Execute_Command (After, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (After, "BC",
         "redo after canonical Character Delete must restore captured After_Text without rerunning range logic");

      Editor.Render_Model.Build_Render_Snapshot (After, Snap);
      Assert
        (Snap.Length = Text_Buffer.Length (After.Buffer),
         "render snapshot length must derive from canonical buffer text only");

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
         "workspace persistence must exclude canonical and removed Character Delete transient state");
      Editor.Keybindings.Reset_To_Defaults;
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Character_Delete_Canonical_Routes_State_And_Persistence;





   procedure Test_Selection_Delete_Command_Descriptors_And_Routes





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
   end Test_Selection_Delete_Command_Descriptors_And_Routes;

   procedure Test_Selection_Delete_Range_Matrix_And_Backward_Selection

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
   end Test_Selection_Delete_Range_Matrix_And_Backward_Selection;

   procedure Test_Selection_Delete_Undo_Redo_Clipboard_Navigation_And_No_Op

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
   end Test_Selection_Delete_Undo_Redo_Clipboard_Navigation_And_No_Op;


   procedure Test_Selection_Delete_Transform_Matrix_And_Caret


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
   end Test_Selection_Delete_Transform_Matrix_And_Caret;

   procedure Test_Selection_Delete_No_Op_Invalid_And_Redo_Preservation

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
   end Test_Selection_Delete_No_Op_Invalid_And_Redo_Preservation;

   procedure Test_Selection_Delete_Find_Dirty_Clipboard_And_Navigation

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
   end Test_Selection_Delete_Find_Dirty_Clipboard_And_Navigation;

   procedure Test_Selection_Delete_Availability_Render_And_Persistence_Boundaries

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
   end Test_Selection_Delete_Availability_Render_And_Persistence_Boundaries;

   procedure Test_Selection_Delete_Active_Buffer_Isolation

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
   end Test_Selection_Delete_Active_Buffer_Isolation;

   procedure Test_Selection_Delete_Selection_Command_And_Edit_Coexistence

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
   end Test_Selection_Delete_Selection_Command_And_Edit_Coexistence;


   function Stripped_Selected_Text
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
   end Stripped_Selected_Text;

   function Anchor_From_Marked
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
   end Anchor_From_Marked;

   function Pos_From_Marked
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
   end Pos_From_Marked;

   function Selected_Text_From_Marked
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
   end Selected_Text_From_Marked;

   procedure Run_Marked_Delete
     (Marked   : String;
      Expected : String;
      Is_Reverse  : Boolean;
      Why      : String)
   is
      S              : Editor.State.State_Type;
      Plain          : constant String := Stripped_Selected_Text (Marked);
      Selected       : constant String := Selected_Text_From_Marked (Marked);
      Anchor         : constant Cursor_Index := Anchor_From_Marked (Marked, Is_Reverse);
      Pos            : constant Cursor_Index := Pos_From_Marked (Marked, Is_Reverse);
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
   end Run_Marked_Delete;

   procedure Test_Selection_Delete_Workflow_Transform_Matrix

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   pragma Unreferenced (T);
   begin
      Run_Marked_Delete ("[Alpha]", "", False, "whole buffer");
      Run_Marked_Delete ("Alpha [Beta]", "Alpha ", False, "suffix word");
      Run_Marked_Delete ("Al[pha Be]ta", "Alta", False, "middle span");
      Run_Marked_Delete ("Alpha[ ]Beta", "AlphaBeta", False, "single space");
      Run_Marked_Delete ("Alpha[" & ASCII.HT & "]Beta", "AlphaBeta", False, "tab");
      Run_Marked_Delete ("Alpha[, ]Beta", "AlphaBeta", False, "punctuation space");
      Run_Marked_Delete ("[Alpha]" & ASCII.LF & "Beta", ASCII.LF & "Beta", False, "prefix before line boundary");
      Run_Marked_Delete ("Alpha" & ASCII.LF & "[Beta]", "Alpha" & ASCII.LF, False, "second line");
      Run_Marked_Delete ("Alpha[" & ASCII.LF & "]Beta", "AlphaBeta", False, "boundary only");
      Run_Marked_Delete ("Alpha[" & ASCII.LF & "Beta]", "Alpha", False, "boundary and text");
      Run_Marked_Delete ("[Alpha" & ASCII.LF & "]Beta", "Beta", False, "first line including boundary");
      Run_Marked_Delete ("Alpha[" & ASCII.LF & ASCII.LF & "]Beta", "AlphaBeta", False, "blank line boundary pair");
      Run_Marked_Delete ("Alpha" & ASCII.LF & "[  " & ASCII.LF & "]Beta", "Alpha" & ASCII.LF & "Beta", False, "whitespace line");
      Run_Marked_Delete ("[Alpha" & ASCII.LF & "Beta" & ASCII.LF & "]", "", False, "trailing newline full buffer");
      Run_Marked_Delete ("Alpha" & ASCII.LF & "[Beta" & ASCII.LF & "]", "Alpha" & ASCII.LF, False, "trailing newline suffix");
   end Test_Selection_Delete_Workflow_Transform_Matrix;

   procedure Test_Forward_Backward_Equivalence_And_Invalid_Noops

     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      procedure Check_Equivalence (Marked : String; Expected : String; Why : String) is
         F : Editor.State.State_Type;
         B : Editor.State.State_Type;
         Plain    : constant String := Stripped_Selected_Text (Marked);
         F_Anchor : constant Cursor_Index := Anchor_From_Marked (Marked, False);
         F_Pos    : constant Cursor_Index := Pos_From_Marked (Marked, False);
         B_Anchor : constant Cursor_Index := Anchor_From_Marked (Marked, True);
         B_Pos    : constant Cursor_Index := Pos_From_Marked (Marked, True);
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
      Check_Equivalence ("Alpha [Beta]", "Alpha ", "word equivalence");
      Check_Equivalence ("Al[pha Be]ta", "Alta", "middle equivalence");
      Check_Equivalence ("Alpha[  ]Beta", "AlphaBeta", "whitespace equivalence");
      Check_Equivalence ("Alpha[,] Beta", "Alpha Beta", "punctuation equivalence");
      Check_Equivalence ("Alpha[" & ASCII.LF & "]Beta", "AlphaBeta", "boundary equivalence");
      Check_Equivalence ("[Alpha" & ASCII.LF & "Beta]", "", "cross-line equivalence");

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
      Assert_Buffer_Text (S, "Alpha Beta", "no selection no-op text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "no selection must preserve redo");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "no selection must not create undo");

      Set_Primary_Selection (S, 3, 3);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta", "empty selection no-op text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "empty selection must preserve redo");

      Set_Primary_Selection (S, 0, 999);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta", "invalid selection no-op text");
      Assert (Message_Text (S) = "Invalid selection",
              "invalid selection message");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "invalid selection must preserve redo");
   end Test_Forward_Backward_Equivalence_And_Invalid_Noops;

   procedure Test_Undo_Redo_Dirty_Find_Clipboard_And_Navigation_Workflow

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
      Assert_Buffer_Text (S, "Alpha  Gamma", "find workflow delete");
      Assert (Editor.State.Is_Dirty (S), "delete must dirty clean buffer");
      Assert (S.Active_Find_Stale, "delete must stale active Find");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "delete must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("DELTA"),
              "delete must not mutate Replace text");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "delete must not mutate Clipboard");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "delete navigation boundary");
      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Assert (Snapshot.Find_Matches_Stale,
              "render must expose stale/current Find policy after edit");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha Beta Gamma", "undo restores text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "undo creates redo");
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Set_Caret (S, 0);
      S.Active_Find_Stale := False;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "no-op delete preserves redo after undo");
      Assert (not S.Active_Find_Stale,
              "no-op delete must not stale Find");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha  Gamma", "redo restores delete");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "redo path still not clipboard-owned");
   end Test_Undo_Redo_Dirty_Find_Clipboard_And_Navigation_Workflow;

   procedure Test_Command_Coexistence_And_Cut_Contrast

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
      Assert_Buffer_Text (S, "", "select-all delete");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "select-all delete must not copy deleted text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Caret (S, 7);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Word);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha  Gamma", "current-word delete");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("Beta"),
              "copy before delete owns clipboard mutation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cut);
      Assert_Buffer_Text (S, "Alpha  Gamma", "cut text effect");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("Beta"),
              "cut owns clipboard mutation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Next);
      Set_Primary_Selection (S, 6, 10);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Gamma", "after char delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Caret (S, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Word_Delete_Next);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_All);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "", "after word delete select-all");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Set_Primary_Selection (S, 5, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta Gamma", "after line split boundary delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);

      Set_Caret (S, 5);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Set_Primary_Selection (S, 5, 6);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Selection_Delete);
      Assert_Buffer_Text (S, "Alpha Beta Gamma", "after line join");
   end Test_Command_Coexistence_And_Cut_Contrast;

   procedure Test_Read_Only_Routes_Feature_And_Persistence_Boundaries

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
         Assert (not Found, "non-goal command exposed: " & Name);
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

      Assert_Buffer_Text (S, To_String (Before_Text), "read-only routes text");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "read-only routes moved caret");
      Assert (S.Carets (S.Carets.First_Index).Anchor = Before_Anchor,
              "read-only routes normalized selection by mutation");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo,
              "read-only routes mutated undo");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "read-only routes mutated redo");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "read-only routes mutated clipboard");
      Assert (Snapshot.Selection_Count = 1,
              "render should project, not consume, canonical selection");

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
         "workspace persistence must exclude Selection Delete transient state");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Alpha"),
              "delete must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Omega"),
              "delete must not mutate Replace text");

      Assert_Not_Exposed ("edit.selection.cut");
      Assert_Not_Exposed ("edit.selection.kill");
      Assert_Not_Exposed ("edit.selection.delete-lines");
      Assert_Not_Exposed ("edit.selection.delete-rect");
      Assert_Not_Exposed ("edit.selection.delete-block");
      Assert_Not_Exposed ("edit.selection.delete-semantic-node");
      Assert_Not_Exposed ("edit.text.delete-range");
      Assert_Not_Exposed ("edit.multi-cursor.delete-selection");
   end Test_Read_Only_Routes_Feature_And_Persistence_Boundaries;


procedure Test_Selection_Delete_Canonical_State_Only_Workflow
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
      Assert (Found_Chord, "test chord must parse");
      Editor.Keybindings.Bind (Chord, Editor.Commands.Command_Selection_Delete);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord);
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert_Buffer_Text
        (After, "Alpha  Gamma",
         "Input_Bridge must route canonical Selection Delete through Executor");
      Assert (Message_Text (After) = "Deleted selection",
              "Selection Delete message mismatch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Selection Delete must create one undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "text-changing Selection Delete must clear redo only after success");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
              "Selection Delete must not mutate Clipboard text");
      Assert (Editor.Clipboard.Has_Text,
              "Selection Delete must not clear Clipboard state");
      Assert (After.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Selection Delete must not mutate Find query");
      Assert (After.Active_Replace_Text = To_Unbounded_String ("Delta"),
              "Selection Delete must not mutate Replace text");
      Assert_Navigation_Counts
        (After, Before_Back, Before_Fwd,
         "Selection Delete must not record navigation history");
      Assert (not Editor.Selection.Has_Selection (After),
              "successful Selection Delete must clear/collapse selection");

      Editor.Executor.Execute_Command (After, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (After, "Alpha Beta Gamma",
         "undo must restore captured Selection Delete Before_Text");
      Editor.Executor.Execute_Command (After, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (After, "Alpha  Gamma",
         "redo must restore captured Selection Delete After_Text");

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
         "persistence must exclude canonical and removed Selection Delete state");

      Editor.Keybindings.Reset_To_Defaults;
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Selection_Delete_Canonical_State_Only_Workflow;



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

   procedure Test_Text_Insert_Basic_Caret_And_Undo

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

      Assert_Buffer_Text (S, "AlXpha", "insert in middle");
      Assert (S.Carets (S.Carets.First_Index).Pos = 3,
              "insert moves caret to payload end");
      Assert (not Editor.Selection.Has_Selection (S),
              "insert leaves no selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "insert creates one undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "insert leaves redo empty");
      Assert (Editor.State.Is_Dirty (S),
              "insert dirties clean buffer");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha", "undo restores text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "AlXpha", "redo restores inserted text");
   end Test_Text_Insert_Basic_Caret_And_Undo;

   procedure Test_Text_Insert_Replaces_Selection_Without_Clipboard

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

      Assert_Buffer_Text (S, "Alpha Gamma", "selection replacement");
      Assert (S.Carets (S.Carets.First_Index).Pos = 11,
              "replacement caret at insert end");
      Assert (not Editor.Selection.Has_Selection (S),
              "replacement clears selection");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "replacement leaves clipboard untouched");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "replacement creates one undo entry");
   end Test_Text_Insert_Replaces_Selection_Without_Clipboard;

   procedure Test_Input_Bridge_Routes_Editor_Text_And_Protects_Overlays

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
      Assert_Buffer_Text (S, "ABeta", "bridge routes editor text input");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "bridge insertion uses undoable mutation");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Open_Quick_Open);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('Z'));
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text (S, "ABeta", "overlay text input does not edit buffer");
   end Test_Input_Bridge_Routes_Editor_Text_And_Protects_Overlays;


   procedure Test_Completeness_Noop_Invalid_And_Redo_Boundaries


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
      Assert_Buffer_Text (S, "Alpha", "empty payload no-op preserves text");
      Assert (Editor.Selection.Has_Selection (S),
              "empty payload no-op preserves valid selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "empty payload creates no undo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "empty payload leaves clean buffer clean");

      Execute_Text_Input (S, String'(1 => ASCII.NUL));
      Assert_Buffer_Text (S, "Alpha", "invalid NUL payload preserves text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "invalid payload creates no undo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "invalid payload leaves dirty state unchanged");

      Set_Caret (S, 5);
      Execute_Text_Input (S, "!");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha", "undo before redo preservation setup");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "undo leaves one redo entry before no-op");

      Execute_Text_Input (S, "");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "no-op after undo preserves redo stack");
      Execute_Text_Input (S, String'(1 => ASCII.NUL));
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "invalid input after undo preserves redo stack");

      Execute_Text_Input (S, "?");
      Assert_Buffer_Text (S, "Alpha?", "successful insert after undo applies text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "successful insert after undo clears redo stack");
   end Test_Completeness_Noop_Invalid_And_Redo_Boundaries;

   procedure Test_Completeness_Backward_Cross_Line_Replacement_And_Persistence

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
         "backward cross-line selection replacement");
      Assert (S.Carets (S.Carets.First_Index).Pos = 3,
              "cross-line replacement caret ends after payload");
      Assert (not Editor.Selection.Has_Selection (S),
              "cross-line replacement clears selection");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "replacement does not read or mutate Clipboard text");
      Assert (Editor.Clipboard.Has_Text,
              "replacement does not clear Clipboard presence");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Text Insert must not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Delta"),
              "Text Insert must not mutate Replace text");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Text Insert must not record Navigation History");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "selection replacement creates one undo entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta" & ASCII.LF & "Gamma",
         "undo restores cross-line replacement text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "AlX" & ASCII.LF & "Gamma",
         "redo restores cross-line replacement text");

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
         "persistence must exclude Text Insert transient state");
   end Test_Completeness_Backward_Cross_Line_Replacement_And_Persistence;

   procedure Test_Completeness_Unicode_Routing_Internal_Surface_And_Isolation

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
         "bridge must route non-Latin text through canonical Text Insert");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "unicode text entry creates one undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "unicode text entry does not create redo entries");

      Resolved :=
        Editor.Commands.Command_Id_From_Stable_Name ("internal.text.insert", Found);
      Assert (not Found and then Resolved = Editor.Commands.No_Command,
              "arbitrary parameterized Text Insert must not be a public stable command");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 4);
      Execute_Text_Input (S, "!");
      Assert_Buffer_Text (S, "Beta!",
                          "insert mutates the active buffer");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text (S, "Alpha",
                          "insert must not mutate inactive buffers");
      Assert (Editor.History.Undo_Stack.Is_Empty,
              "inactive buffer must not inherit text-insert undo entries");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text (S, "Beta!",
                          "switched active buffer preserves inserted text");
      Assert (not Editor.History.Undo_Stack.Is_Empty,
              "active buffer retains its own text-insert undo entry");

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      S.Carets.Clear;
      Execute_Text_Input (S, "X");
      Assert_Buffer_Text (S, "Beta!",
                          "no-caret text insert must not mutate text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "no-caret text insert creates no undo entry");
   end Test_Completeness_Unicode_Routing_Internal_Surface_And_Isolation;


   procedure Test_Remove_Removed_Name_Text_Input_Uses_Canonical_Path


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
         "canonical Text Insert must use canonical selection replacement");
      Assert (S.Carets (S.Carets.First_Index).Pos = 7,
              "canonical Text Insert replacement moves caret to payload end");
      Assert (not Editor.Selection.Has_Selection (S),
              "canonical Text Insert replacement clears selection");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "canonical Text Insert canonical path does not touch Clipboard");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "canonical Text Insert must not mutate Find query text");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "canonical Text Insert must invalidate Find through text-edit hook");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "canonical Text Insert must not record Navigation History");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "canonical Text Insert creates exactly one undo entry");
   end Test_Remove_Removed_Name_Text_Input_Uses_Canonical_Path;

   procedure Test_Completeness_Line_Boundary_Command_Is_Canonical_Insert

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
         "Insert Newline command must normalize through canonical Text Insert");
      Assert (S.Carets (S.Carets.First_Index).Pos = 6,
              "line-boundary payload moves caret after canonical boundary");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "line-boundary insertion creates one undo entry");
      Assert (S.Active_Find_Stale,
              "line-boundary insertion invalidates Find through text-edit hook");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "AlphaBeta",
         "undo restores text before line-boundary insertion");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "Alpha" & ASCII.LF & "Beta",
         "redo restores exact line-boundary payload");
   end Test_Completeness_Line_Boundary_Command_Is_Canonical_Insert;

   procedure Test_Completeness_Multi_Caret_Insert_Is_Not_Second_Model

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
         "direct multi-caret Insert_Text_Input must be rejected by the canonical single-caret path");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "rejected multi-caret insertion creates no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "rejected multi-caret insertion creates no redo entry");
   end Test_Completeness_Multi_Caret_Insert_Is_Not_Second_Model;

   procedure Test_Text_Insert_Caret_Transform_Matrix

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
                   "insert at buffer start");
      Case_Insert ("Alpha", 5, "!", "Alpha!", 6,
                   "insert at buffer end");
      Case_Insert ("Alpha", 2, "X", "AlXpha", 3,
                   "insert in middle of ordinary text");
      Case_Insert ("Alpha Beta", 6, "_", "Alpha _Beta", 7,
                   "insert adjacent to whitespace");
      Case_Insert ("Alpha.Beta", 5, ".", "Alpha..Beta", 6,
                   "insert adjacent to punctuation");
      Case_Insert ("", 0, "A", "A", 1,
                   "insert into empty buffer");
      Case_Insert ("AlphaBeta", 5, "123", "Alpha123Beta", 8,
                   "insert multi-character payload");
      Case_Insert ("AlphaBeta", 5, " ", "Alpha Beta", 6,
                   "insert literal space payload");
      Case_Insert ("AlphaBeta", 5, String'(1 => ASCII.HT),
                   "Alpha" & ASCII.HT & "Beta", 6,
                   "insert literal tab payload");
      Case_Insert ("AlphaBeta", 5, String'(1 => ASCII.LF),
                   "Alpha" & ASCII.LF & "Beta", 6,
                   "insert canonical line-boundary payload");
   end Test_Text_Insert_Caret_Transform_Matrix;


   procedure Test_Text_Insert_Replacement_Transform_Matrix


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
                    "replace select-all");
      Case_Replace ("Alpha Beta", 6, 10, "Gamma", "Alpha Gamma", 11,
                    "replace single-line selection");
      Case_Replace ("Alpha Beta", 8, 3, "X", "AlpXta", 4,
                    "replace backward selection equivalently");
      Case_Replace ("Alpha Beta", 5, 6, "_", "Alpha_Beta", 6,
                    "replace whitespace selection");
      Case_Replace ("Alpha.Beta", 5, 6, "!", "Alpha!Beta", 6,
                    "replace punctuation selection");
      Case_Replace ("Alpha" & ASCII.HT & "Beta", 5, 6, " ",
                    "Alpha Beta", 6,
                    "replace tab selection");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 5, 6, " ",
                    "Alpha Beta", 6,
                    "replace line-boundary-only selection");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 0, 6, "X",
                    "XBeta", 1,
                    "replace through first line boundary");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 5, 10, "X",
                    "AlphaX", 6,
                    "replace through trailing selected text");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 0, 10, "X",
                    "X", 1,
                    "replace cross-line select-all");
   end Test_Text_Insert_Replacement_Transform_Matrix;


   procedure Test_Text_Insert_Noop_Invalid_And_Redo_Are_NonMutating


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
      Assert_Buffer_Text (S, "Alpha", "empty payload preserves text");
      Assert (Editor.Selection.Has_Selection (S),
              "empty payload preserves valid selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "empty payload creates no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "empty payload preserves redo stack");
      Assert (not Editor.State.Is_Dirty (S),
              "empty payload preserves dirty state");
      Assert (not S.Active_Find_Stale,
              "empty payload must not invalidate Find state");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "empty payload leaves Clipboard text untouched");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "empty payload records no navigation");

      Execute_Text_Input (S, String'(1 => ASCII.NUL));
      Assert_Buffer_Text (S, "Alpha", "NUL payload preserves text");
      Assert (Editor.Selection.Has_Selection (S),
              "NUL payload preserves selection");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "NUL payload preserves redo stack");
      Assert (not S.Active_Find_Stale,
              "NUL payload must not invalidate Find state");

      Execute_Text_Input (S, String'(1 => ASCII.CR));
      Assert_Buffer_Text (S, "Alpha", "CR payload preserves text");
      Assert (Editor.Selection.Has_Selection (S),
              "CR payload preserves selection");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "CR payload preserves redo stack");

      Execute_Text_Input (S, String'(1 => ASCII.ESC));
      Assert_Buffer_Text (S, "Alpha", "ESC payload preserves text");
      Assert (Editor.Selection.Has_Selection (S),
              "ESC payload preserves selection");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "ESC payload preserves redo stack");
   end Test_Text_Insert_Noop_Invalid_And_Redo_Are_NonMutating;


   procedure Test_Text_Insert_Invalid_Selection_Does_Not_Repair_State


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
         "invalid multi-caret Text Insert must not mutate text");
      Assert (Natural (S.Carets.Length) = 2,
              "invalid multi-caret Text Insert must not collapse carets");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "invalid multi-caret Text Insert creates no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "invalid multi-caret Text Insert creates no redo entry");

      S.Rect_Select_Active := True;
      Execute_Text_Input (S, "Y");
      Assert_Buffer_Text
        (S, "Alpha Beta",
         "rectangular Text Insert failure must not mutate text");
      Assert (Natural (S.Carets.Length) = 2,
              "rectangular Text Insert failure must not repair carets");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "rectangular Text Insert failure creates no undo entry");
   end Test_Text_Insert_Invalid_Selection_Does_Not_Repair_State;


   procedure Test_Text_Insert_Find_Clipboard_Navigation_And_Persistence


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

      Assert_Buffer_Text (S, "Alpha XBeta", "insert before find match");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Text Insert does not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Gamma"),
              "Text Insert does not mutate Replace text");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Text Insert invalidates Find through canonical text-edit hook");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Text Insert does not mutate Clipboard text");
      Assert (Editor.Clipboard.Has_Text,
              "Text Insert does not clear Clipboard presence");
      Assert_Navigation_Counts
        (S, Before_Back, Before_Fwd,
         "Text Insert records no Navigation History");

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
         "persistence must exclude Text Insert transient state");
   end Test_Text_Insert_Find_Clipboard_Navigation_And_Persistence;


   procedure Test_Completeness_Active_Buffer_Render_And_Overlay_Routing


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

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 4);
      Execute_Text_Input (S, "!");
      Assert_Buffer_Text
        (S, "Beta!",
         "completeness Text Insert mutates only active buffer B");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "completeness active buffer B receives one undo entry");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text
        (S, "Alpha",
         "completeness inactive buffer A remains unchanged");
      Assert (Editor.History.Undo_Stack.Is_Empty,
              "completeness inactive buffer A has no Text Insert undo entry");

      Set_Caret (S, 0);
      Execute_Text_Input (S, "A");
      Assert_Buffer_Text
        (S, "AAlpha",
         "completeness buffer A can be edited independently after switch");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "completeness buffer A has its own undo entry");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text
        (S, "Beta!",
         "completeness buffer B retains independent inserted text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "Beta",
         "completeness undo in buffer B affects only buffer B");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text
        (S, "AAlpha",
         "completeness undo in B does not change buffer A");

      --  Rendering observes current text/caret state only.  It must not repair,
      --  insert, clear redo, mutate dirty state, or produce editor text-entry
      --  side effects.
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "completeness render snapshot reflects buffer length");
      Assert_Buffer_Text
        (S, "AAlpha",
         "completeness render snapshot must not insert text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "completeness render snapshot must not mutate undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "completeness render snapshot must not mutate redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "completeness render snapshot must not mutate dirty state");

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
         "completeness bridge editor focus routes through Text Insert");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "completeness bridge editor text creates one undo entry");

      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Open_Quick_Open);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('Z'));
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text
        (S, "CoXre",
         "completeness Quick Open text input must not leak into buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "completeness overlay text input must not create buffer undo entries");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "completeness overlay text input must not mutate buffer redo entries");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "completeness overlay text input must not mutate buffer dirty state");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Completeness_Active_Buffer_Render_And_Overlay_Routing;


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


   procedure Test_Text_Insert_Workflow_Transform_And_Replacement


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
                   "insert at buffer start end-to-end");
      Case_Insert ("Alpha", 5, "!", "Alpha!", 6,
                   "insert at buffer end end-to-end");
      Case_Insert ("Alphabeta", 5, "123", "Alpha123beta", 8,
                   "multi-character insert at caret");
      Case_Insert ("AlphaBeta", 5, " ", "Alpha Beta", 6,
                   "space payload insert policy");
      Case_Insert ("AlphaBeta", 5, String'(1 => ASCII.HT),
                   "Alpha" & ASCII.HT & "Beta", 6,
                   "tab payload insert policy");
      Case_Insert ("AlphaBeta", 5, String'(1 => ASCII.LF),
                   "Alpha" & ASCII.LF & "Beta", 6,
                   "line-boundary payload insert policy");
      Case_Insert ("", 0, "A", "A", 1,
                   "empty buffer insert policy");

      Case_Replace ("Alpha", 0, 5, "Beta", "Beta", 4, "Alpha",
                    "select-all replacement");
      Case_Replace ("Alpha Beta", 6, 10, "Gamma", "Alpha Gamma", 11, "Beta",
                    "forward single-line replacement");
      Case_Replace ("Alpha Beta", 10, 6, "Gamma", "Alpha Gamma", 11, "Beta",
                    "backward single-line replacement equivalence");
      Case_Replace ("Alpha Beta", 5, 6, "_", "Alpha_Beta", 6, " ",
                    "whitespace replacement");
      Case_Replace ("Alpha.Beta", 5, 6, "!", "Alpha!Beta", 6, ".",
                    "punctuation replacement");
      Case_Replace ("Alpha" & ASCII.HT & "Beta", 5, 6, " ", "Alpha Beta", 6,
                    String'(1 => ASCII.HT),
                    "tab replacement");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 5, 6, " ", "Alpha Beta", 6,
                    String'(1 => ASCII.LF),
                    "line-boundary replacement");
      Case_Replace ("Alpha" & ASCII.LF & "Beta", 0, 11, "X", "X", 1,
                    "Alpha" & ASCII.LF & "Beta",
                    "cross-line select-all replacement");
   end Test_Text_Insert_Workflow_Transform_And_Replacement;


   procedure Test_Text_Insert_Noops_Redo_Dirty_And_Find


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
      Assert_Buffer_Text (S, "Alpha", "empty payload must not delete selection");
      Assert (Editor.Selection.Has_Selection (S),
              "empty payload preserves valid selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "empty payload creates no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "empty payload creates no redo entry");
      Assert (not Editor.State.Is_Dirty (S),
              "empty payload preserves dirty state");
      Assert (not S.Active_Find_Stale,
              "empty payload does not invalidate Find");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "empty payload leaves Clipboard text unchanged");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "empty payload records no Navigation History");

      Execute_Text_Input (S, String'(1 => ASCII.NUL));
      Assert_Buffer_Text (S, "Alpha", "NUL payload must not mutate text");
      Assert (Editor.Selection.Has_Selection (S),
              "NUL payload preserves selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "NUL payload creates no undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "NUL payload preserves redo stack");
      Assert (not Editor.State.Is_Dirty (S),
              "NUL payload preserves dirty state");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 0
              and then S.Carets (S.Carets.First_Index).Pos = 5,
              "NUL payload preserves selection anchor/focus");
      Assert (not S.Active_Find_Stale,
              "NUL payload does not invalidate Find");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "NUL payload leaves Clipboard text unchanged");
      Assert_Navigation_Counts (S, Before_Back, Before_Fwd,
                                "NUL payload records no Navigation History");

      Set_Caret (S, 5);
      Execute_Text_Input (S, "!");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Alpha", "redo preservation setup undo restores clean text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "undo leaves redo available before no-op/failure");

      Execute_Text_Input (S, "");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "empty payload preserves redo stack after undo");
      Execute_Text_Input (S, String'(1 => ASCII.ESC));
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "invalid payload preserves redo stack after undo");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Alpha!", "redo still restores prior edit after failed Text Insert");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Set_Primary_Selection (S, 0, 5);
      Execute_Text_Input (S, "Q");
      Assert_Buffer_Text (S, "Q", "successful replacement after undo applies new text");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "successful replacement after undo clears redo stack");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text (S, "Q", "redo after invalidation leaves replacement text unchanged");
   end Test_Text_Insert_Noops_Redo_Dirty_And_Find;


   procedure Test_Text_Insert_Clipboard_Navigation_Active_Buffer_And_Overlay_Workflow


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
         "Text Insert ignores Clipboard and Navigation History");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Paste);
      Assert_Buffer_Text
        (S, "AlphaXCLIP",
         "Paste still uses original Clipboard after Text Insert");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Text Insert did not consume Clipboard before Paste");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "Beta");
      Set_Caret (S, 4);
      Execute_Text_Input (S, "!");
      Assert_Buffer_Text (S, "Beta!", "active buffer B receives Text Insert");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert_Buffer_Text (S, "AlphaXCLIP", "inactive buffer A retained its own text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "AlphaX", "undo in A affects only A");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert_Buffer_Text (S, "Beta!", "switch back to B preserves B inserted text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text (S, "Beta", "undo in B affects only B");

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
      Assert_Buffer_Text (S, "CoYre", "editor focus text-entry routes to canonical insertion");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Input_Bridge editor insertion creates canonical undo entry");

      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Open_Quick_Open);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (Character'Pos ('Z'));
      Editor.Input_Bridge.Handle (Cmd);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert_Buffer_Text (S, "CoYre", "Quick Open field consumes text before editor buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "overlay input creates no buffer undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "overlay input preserves buffer redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "overlay input preserves dirty state");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Text_Insert_Clipboard_Navigation_Active_Buffer_And_Overlay_Workflow;


   procedure Test_Text_Insert_Mixed_Editing_Features_Render_And_Persistence


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
                          "mixed workflow starts with Text Insert");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Char_Delete_Previous);
      Assert_Buffer_Text (S, "Alpha Beta" & ASCII.LF & "Gamma",
                          "Character Delete consumes canonical post-insert text");
      Execute_Text_Input (S, "Y");
      Assert_Buffer_Text (S, "AlphaY Beta" & ASCII.LF & "Gamma",
                          "Text Insert works after Character Delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Word_Delete_Previous);
      Assert_Buffer_Text (S, " Beta" & ASCII.LF & "Gamma",
                          "Word Delete consumes canonical post-insert text");
      Execute_Text_Input (S, "Alpha");
      Assert_Buffer_Text (S, "Alpha Beta" & ASCII.LF & "Gamma",
                          "Text Insert works after Word Delete");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Split_At_Caret);
      Execute_Text_Input (S, "T");
      Assert_Buffer_Text (S, "Alpha" & ASCII.LF & "T Beta" & ASCII.LF & "Gamma",
                          "Text Insert works after Line Split");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Line_Join_Next);
      Execute_Text_Input (S, "U");
      Assert (Index (To_Unbounded_String (Buffer_Text (S)), "U") > 0,
              "Text Insert works after Line Join");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Indent_Increase);
      Execute_Text_Input (S, "V");
      Assert (Index (To_Unbounded_String (Buffer_Text (S)), "V") > 0,
              "Text Insert works after Indentation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Line_Comment);
      Execute_Text_Input (S, "W");
      Assert (Index (To_Unbounded_String (Buffer_Text (S)), "W") > 0,
              "Text Insert works after Line Comment toggle");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "mixed editing workflow leaves Clipboard owned by Clipboard commands only");

      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Dirty_Before := Editor.State.Is_Dirty (S);
      Text_Before := To_Unbounded_String (Buffer_Text (S));
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Fwd_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Length = Text_Buffer.Length (S.Buffer),
              "render snapshot reflects current text length");
      Assert (To_Unbounded_String (Buffer_Text (S)) = Text_Before,
              "render snapshot must not mutate text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "render snapshot must not mutate undo stack");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "render snapshot must not mutate redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "render snapshot must not mutate dirty state");
      Assert_Navigation_Counts (S, Back_Before, Fwd_Before,
                                "render snapshot records no Navigation History");

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
         "persistence excludes Text Insert transient/policy/history state");
   end Test_Text_Insert_Mixed_Editing_Features_Render_And_Persistence;


   procedure Test_Text_Insert_Overlay_Owner_Matrix_And_Command_Surface


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
                 "non-goal command exposed: " & Name);
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
              "newline text input command remains hidden from the palette");
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
         "explicit newline route inserts canonical line boundary");
      Assert (Message_Text (S) = "Inserted text",
              "explicit newline route reports Text Insert only");
      Assert (Message_Text (S) /= "Split line",
              "newline route must not report Line Split participation");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "explicit newline creates exactly one undo entry");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "explicit newline does not touch Clipboard");
      Assert_Navigation_Counts
        (S, Back_Before, Fwd_Before,
         "explicit newline records no Navigation History");

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
         "Go To Line prompt consumes text before buffer insertion");
      Assert (Snap.Goto_Line_Visible
              and then To_String (Snap.Goto_Line_Query) = "3",
              "Go To Line query receives overlay text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Go To Line input creates no buffer undo entry");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Go To Line input preserves buffer redo stack");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "Go To Line input preserves buffer dirty state");

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
         "Find prompt consumes text before buffer insertion");
      Assert (Snap.Find_Visible and then To_String (Snap.Find_Query) = "B",
              "Find query receives overlay text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Find prompt input creates no buffer undo entry");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "Find prompt input preserves dirty state");

      --  Replace prompt state is independent from Text Insert.  Text Insert
      --  may stale Find ranges through the canonical edit hook, but it must
      --  not rewrite the replacement text or prompt state.
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run Run");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 3);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Execute_Text_Input (S, "!");
      Assert_Buffer_Text
        (S, "Run! Run",
         "Text Insert mutates only buffer text under Replace state");
      Assert (S.Active_Replace_Prompt
              and then To_String (S.Active_Replace_Text) = "Execute",
              "Text Insert preserves Replace prompt text/state");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Run"),
              "Text Insert preserves Find query while invalidating ranges");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Text Insert invalidates Find ranges through edit hook only");
   end Test_Text_Insert_Overlay_Owner_Matrix_And_Command_Surface;








   procedure Test_Text_Insert_Canonical_Route_State_And_Persistence








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
         "canonical Text Insert replacement mutates active buffer only once");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "replacement remains one canonical undoable edit");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "replacement creates no redo entry");
      Assert (Editor.State.Is_Dirty (S),
              "replacement uses canonical dirty policy");
      Assert (S.Active_Find_Query = To_Unbounded_String ("Beta"),
              "Text Insert does not mutate Find query");
      Assert (S.Active_Replace_Text = To_Unbounded_String ("Gamma"),
              "Text Insert does not mutate Replace text");
      Assert (S.Active_Find_Stale and then S.Active_Find_Matches.Is_Empty,
              "Text Insert invalidates Find through canonical hook");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Text Insert never reads or mutates Clipboard text");
      Assert_Navigation_Counts
        (S, Back_Before, Fwd_Before,
         "Text Insert records no Navigation History");

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
         "persistence excludes canonical and removed Text Insert transient state");

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
         "overlay text-entry must not leak into active-buffer insertion");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "overlay text-entry creates no active-buffer undo entry");
      Assert (Editor.State.Is_Dirty (S) = Dirty_Before,
              "overlay text-entry preserves active-buffer dirty state");
   end Test_Text_Insert_Canonical_Route_State_And_Persistence;


   procedure Test_Text_Insert_Behavior_Preservation_Smoke


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
         "accepted whitespace/tab/punctuation payload inserts exactly");
      Assert (S.Carets (S.Carets.First_Index).Pos = 4,
              "insert-at-caret moves caret to payload end");

      Set_Primary_Selection (S, 4, 1);
      Execute_Text_Input (S, "X" & ASCII.LF & "Y");
      Assert_Buffer_Text
        (S, "AX" & ASCII.LF & "YB",
         "backward replacement keeps canonical line-boundary payload policy");
      Assert (S.Carets (S.Carets.First_Index).Pos = 4,
              "replacement moves caret to payload end");
      Assert (not Editor.Selection.Has_Selection (S),
              "replacement clears active selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 2,
              "insert plus replacement are two canonical undo entries");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "A " & ASCII.HT & ".B",
         "undo restores replacement Before_Text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "AX" & ASCII.LF & "YB",
         "redo restores replacement After_Text without replaying Text Insert");

      Execute_Text_Input (S, "");
      Assert_Buffer_Text
        (S, "AX" & ASCII.LF & "YB",
         "empty payload remains a non-mutating no-op");
      Execute_Text_Input (S, String'(1 => ASCII.CR));
      Assert_Buffer_Text
        (S, "AX" & ASCII.LF & "YB",
         "invalid payload remains non-mutating");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "behavior smoke preserves Clipboard boundary");
   end Test_Text_Insert_Behavior_Preservation_Smoke;



   procedure Test_Trim_Trailing_Whitespace_Command_Surface
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
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Format_Buffer) =
         "edit.format-buffer",
         "format buffer stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Format_Buffer).Category =
         Editor.Commands.Edit_Category,
         "format buffer must be an Edit command");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Format_Buffer),
         "format buffer must be bindable");
      Assert
        (Editor.Commands.Is_Text_Editing_Command
           (Editor.Commands.Command_Format_Buffer),
         "format buffer must be classified as text editing");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Format_Selected_Text) =
         "edit.format.selection",
         "format selection stable name mismatch");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Format_Selected_Text).Category =
         Editor.Commands.Edit_Category,
         "format selection must be an Edit command");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Format_Selected_Text),
         "format selection must be bindable");
      Assert
        (Editor.Commands.Is_Text_Editing_Command
           (Editor.Commands.Command_Format_Selected_Text),
         "format selection must be classified as text editing");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.trim-trailing-whitespace", Found);
      Assert (Found, "trim trailing whitespace stable name must resolve");
      Assert
        (Id = Editor.Commands.Command_Trim_Trailing_Whitespace,
         "trim trailing whitespace stable name resolves wrong command");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.format-buffer", Found);
      Assert (Found, "format buffer stable name must resolve");
      Assert
        (Id = Editor.Commands.Command_Format_Buffer,
         "format buffer stable name resolves wrong command");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.format.selection", Found);
      Assert (Found, "format selection stable name must resolve");
      Assert
        (Id = Editor.Commands.Command_Format_Selected_Text,
         "format selection stable name resolves wrong command");
   end Test_Trim_Trailing_Whitespace_Command_Surface;

   procedure Test_Expected_Command_Names_Resolve
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
         Assert (Found, "expected command name did not resolve: " & Name);
         Assert
           (Id = Expected,
            "expected command name resolved to wrong command: " & Name);
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
      Assert_Resolves ("edit.format-buffer", Editor.Commands.Command_Format_Buffer);
      Assert_Resolves ("edit.format.document", Editor.Commands.Command_Format_Buffer);
      Assert_Resolves ("edit.format.selection", Editor.Commands.Command_Format_Selected_Text);
   end Test_Expected_Command_Names_Resolve;

   procedure Test_Format_Buffer_Uses_Explicit_Whitespace_Formatter
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Found : Boolean := False;
      Id : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "procedure P is  " & ASCII.LF &
            "begin" & ASCII.HT & ASCII.LF &
            "   null;" & ASCII.LF &
            "end P;");
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 1);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Format_Buffer);

      Assert_Buffer_Text
        (S, "procedure P is" & ASCII.LF &
            "begin" & ASCII.LF &
            "   null;" & ASCII.LF &
            "end P;",
         "format buffer should apply the explicit active-buffer formatter");
      Assert (Message_Text (S) = "Trimmed trailing whitespace",
              "format buffer should report the formatter edit result");
      Assert (Editor.State.Is_Dirty (S),
              "format buffer should dirty the active buffer only when text changes");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "format buffer should create one undoable edit group");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "procedure P is  " & ASCII.LF &
            "begin" & ASCII.HT & ASCII.LF &
            "   null;" & ASCII.LF &
            "end P;",
         "format buffer undo should restore original text");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("file.format-on-save", Found);
      Assert (Found and then Id = Editor.Commands.Command_Toggle_Format_On_Save,
              "format buffer command surface should expose format-on-save toggle");
   end Test_Format_Buffer_Uses_Explicit_Whitespace_Formatter;

   procedure Test_Format_Selection_Uses_Selected_Line_Formatter
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
        (S, "one  " & ASCII.LF & "two  " & ASCII.LF & "three" & ASCII.HT);
      Editor.State.Set_Dirty (S, False);
      Set_Caret (S, 1);
      Assert
        (Editor.Commands.Command_Format_Selected_Text /=
         Editor.Commands.Command_Find_From_Selection,
         "format selection command id must not alias find-from-selection");
      Assert
        (Editor.Commands.Command_Format_Selected_Text /=
         Editor.Commands.Command_Project_Search_From_Selection,
         "format selection command id must not alias project-search-from-selection");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Format_Selected_Text);
      Assert
        (A.Status = Editor.Commands.Command_Unavailable,
         "format selection must require an active selection");
      Assert
        (Editor.Commands.Unavailable_Reason (A) = "No selected text",
         "format selection no-selection availability reason mismatch: "
         & Editor.Commands.Unavailable_Reason (A));

      Set_Primary_Selection (S, 7, 10);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Format_Selected_Text);

      Assert_Buffer_Text
        (S, "one  " & ASCII.LF & "two" & ASCII.LF & "three" & ASCII.HT,
         "format selection should apply only to selected logical lines");
      Assert (Message_Text (S) = "Trimmed trailing whitespace",
              "format selection should report the formatter edit result");
      Assert (Editor.State.Is_Dirty (S),
              "format selection should dirty the active buffer when text changes");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "format selection should create one undoable edit group");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "one  " & ASCII.LF & "two  " & ASCII.LF & "three" & ASCII.HT,
         "format selection undo should restore original selected-line text");
   end Test_Format_Selection_Uses_Selected_Line_Formatter;

   procedure Test_Trim_Trailing_Whitespace_Edit_Group
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
         "trim must remove only line-end spaces and tabs");
      Assert (Message_Text (S) = "Trimmed trailing whitespace",
              "trim message mismatch");
      Assert (Editor.State.Is_Dirty (S),
              "trim must dirty the active buffer when text changes");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "trim must create one grouped undo step");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "trim must not create redo entries");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "alpha  " & ASCII.LF & "be" & ASCII.HT & ASCII.HT & ASCII.LF & "ta",
         "trim undo must restore original whitespace");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert_Buffer_Text
        (S, "alpha" & ASCII.LF & "be" & ASCII.LF & "ta",
         "trim redo must reapply grouped trim");
   end Test_Trim_Trailing_Whitespace_Edit_Group;

   procedure Test_Trim_Trailing_Whitespace_Noop_Is_Nonmutating
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
         "trim no-op must preserve text");
      Assert (Message_Text (S) = "No trailing whitespace",
              "trim unavailable/no-op message mismatch");
      Assert (not Editor.State.Is_Dirty (S),
              "trim no-op must not dirty the buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "trim no-op must not create an undo entry");
   end Test_Trim_Trailing_Whitespace_Noop_Is_Nonmutating;


   procedure Test_Trim_Trailing_Whitespace_Selected_Lines_Only
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
         "selected-line trim must leave unselected trailing whitespace intact");
      Assert (Editor.State.Is_Dirty (S),
              "selected-line trim must dirty when text changes");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "selected-line trim must create one grouped undo step");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert_Buffer_Text
        (S, "one  " & ASCII.LF & "two  " & ASCII.LF & "three" & ASCII.HT,
         "selected-line trim undo must restore only the grouped trim");
   end Test_Trim_Trailing_Whitespace_Selected_Lines_Only;

   procedure Test_Selected_Line_Trim_Noop_Does_Not_Clean_Other_Lines
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
         "selected clean line trim must not trim unselected lines");
      Assert (Message_Text (S) = "No trailing whitespace",
              "selected clean line trim unavailable/no-op message mismatch");
      Assert (not Editor.State.Is_Dirty (S),
              "selected clean line trim no-op must not dirty");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "selected clean line trim no-op must not create undo");
   end Test_Selected_Line_Trim_Noop_Does_Not_Clean_Other_Lines;


   procedure Test_Trim_Availability_Is_Precise_And_Side_Effect_Free
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
         "clean-buffer trim availability must be unavailable");
      Assert
        (Editor.Commands.Unavailable_Reason (A) = "No trailing whitespace",
         "clean-buffer trim availability reason mismatch");
      Assert_Buffer_Text
        (S, "alpha" & ASCII.LF & "beta",
         "trim availability must not mutate text");
      Assert (not Editor.State.Is_Dirty (S),
              "trim availability must not dirty the buffer");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "trim availability must not create undo history");
   end Test_Trim_Availability_Is_Precise_And_Side_Effect_Free;

   procedure Test_Selected_Trim_Availability_Uses_Selected_Lines
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
         "selected clean line trim availability must be unavailable");
      Assert
        (Editor.Commands.Unavailable_Reason (A) = "No trailing whitespace",
         "selected clean line trim availability reason mismatch");
      Assert_Buffer_Text
        (S, "one  " & ASCII.LF & "two" & ASCII.LF & "three  ",
         "selected-line trim availability must not trim other lines");
      Assert (not Editor.State.Is_Dirty (S),
              "selected-line trim availability must not dirty");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0,
              "selected-line trim availability must not create undo");
   end Test_Selected_Trim_Availability_Uses_Selected_Lines;



   procedure Test_Command_Palette_Projects_Canonical_Indentation_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Indent_Command_Descriptors (T);
   end Test_Command_Palette_Projects_Canonical_Indentation_Only;

   procedure Test_Keybindings_Reject_Removed_Name_Indentation_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Indent_Input_Bridge_And_Availability_Side_Effects (T);
   end Test_Keybindings_Reject_Removed_Name_Indentation_Names;

   procedure Test_Canonical_Indentation_Path_And_Persistence_Exclusion
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Indent_Increase_Workflow_Matrix (T);
   end Test_Canonical_Indentation_Path_And_Persistence_Exclusion;

   procedure Test_Keybindings_Reject_Removed_Name_Line_Comment_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Canonical_Line_Comment_Path_And_Persistence_Exclusion (T);
   end Test_Keybindings_Reject_Removed_Name_Line_Comment_Names;

   procedure Test_Line_Join_Canonical_Cleanup_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Line_Join_Canonical_Behavior_And_Persistence (T);
   end Test_Line_Join_Canonical_Cleanup_Surface;

   procedure Test_Line_Split_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Line_Split_Canonical_Behavior_And_State_Boundaries (T);
   end Test_Line_Split_Canonical_Surface_Cleanup;

   procedure Test_Character_Delete_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Character_Delete_Canonical_Routes_State_And_Persistence (T);
   end Test_Character_Delete_Canonical_Surface_Cleanup;

   procedure Test_Selection_Delete_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Selection_Delete_Canonical_State_Only_Workflow (T);
   end Test_Selection_Delete_Canonical_Surface_Cleanup;

   overriding procedure Register_Tests (T : in out Line_Edit_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Trim_Trailing_Whitespace_Command_Surface'Access,
         "Trim Trailing Whitespace Command Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Expected_Command_Names_Resolve'Access,
         "Expected Command Names Resolve");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Buffer_Uses_Explicit_Whitespace_Formatter'Access,
         "Format Buffer Uses Explicit Whitespace Formatter");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Selection_Uses_Selected_Line_Formatter'Access,
         "Format Selection Uses Selected Line Formatter");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Trim_Trailing_Whitespace_Edit_Group'Access,
         "Trim Trailing Whitespace Edit Group");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Trim_Trailing_Whitespace_Noop_Is_Nonmutating'Access,
         "Trim Trailing Whitespace Noop Is Nonmutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Trim_Trailing_Whitespace_Selected_Lines_Only'Access,
         "Trim Trailing Whitespace Selected Lines Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Line_Trim_Noop_Does_Not_Clean_Other_Lines'Access,
         "Selected Line Trim Noop Does Not Clean Other Lines");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Trim_Availability_Is_Precise_And_Side_Effect_Free'Access,
         "Trim Availability Is Precise And Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Trim_Availability_Uses_Selected_Lines'Access,
         "Selected Trim Availability Uses Selected Lines");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Descriptors'Access,
         "Line Edit Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Current_Line_Undo_Redo'Access,
         "Delete Current Line Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Duplicate_Current_Line'Access,
         "Duplicate Current Line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Line_Up_Down_And_Boundaries'Access,
         "Move Line Up Down Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Empty_Buffer_No_Ops'Access,
         "Empty Buffer No Ops");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_First_Last_And_One_Line'Access,
         "Delete First Last And One Line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Duplicate_Last_Line_Undo_Redo'Access,
         "Duplicate Last Line Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Last_Line_Move_Down_No_Op_Preserves_Redo_Dirty'Access,
         "Last Line Move Down No Op Preserves Redo Dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clipboard_Selection_Navigation_Boundaries'Access,
         "Clipboard Selection Navigation Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Input_Bridge_Routes_Line_Commands'Access,
         "Input Bridge Routes Line Commands");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Availability_Has_No_Side_Effects'Access,
         "Availability Has No Side Effects");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Trailing_Newline_Line_Boundaries'Access,
         "Trailing Newline Line Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Blank_Whitespace_And_EOF_Lines'Access,
         "Delete Blank Whitespace And EOF Lines");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Duplicate_Whitespace_And_Caret_Clamp'Access,
         "Duplicate Whitespace And Caret Clamp");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Blank_Line_And_Attached_Caret'Access,
         "Move Blank Line And Attached Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Redo_Find_And_Boundary_No_Op_Reliability'Access,
         "Redo Find And Boundary No Op Reliability");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Duplicate_Move_Workflow_Consistency'Access,
         "Delete Duplicate Move Workflow Consistency");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Terminator_Matrix_Undo_Redo'Access,
         "Line Terminator Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Clipboard_Find_Redo_Boundaries'Access,
         "Selection Clipboard Find Redo Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_History_Clear_And_No_Op_Policy'Access,
         "Dirty History Clear And No Op Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Availability_Projection_And_Non_Goal_Surface'Access,
         "Availability Projection And Non Goal Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keybinding_Config_Rejects_Removed_Name_Line_Names'Access,
         "Keybinding Config Rejects Removed_Name Line Names");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Default_Keybindings_And_Runtime_Routes_Are_Canonical'Access,
         "Default Keybindings And Runtime Routes Are Canonical");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Command_Descriptors'Access,
         "Indent Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Increase_Undo_Redo_And_Caret'Access,
         "Indent Increase Undo Redo And Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Increase_Blank_Whitespace_And_Empty_Buffer'Access,
         "Indent Increase Blank Whitespace And Empty Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Outdent_Policy_Undo_Redo_And_No_Op'Access,
         "Outdent Policy Undo Redo And No Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Selection_Clipboard_Find_And_Navigation_Boundaries'Access,
         "Indent Selection Clipboard Find And Navigation Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Input_Bridge_And_Availability_Side_Effects'Access,
         "Indent Input Bridge And Availability Side Effects");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Leading_Whitespace_Outdent_Matrix'Access,
         "Leading Whitespace Outdent Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Exact_Unit_And_Line_Boundaries'Access,
         "Indent Exact Unit And Line Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Redo_Find_Selection_Clipboard_And_Navigation_Reliability'Access,
         "Redo Find Selection Clipboard And Navigation Reliability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Edit_Coexistence_And_Current_Line_Only'Access,
         "Line Edit Coexistence And Current Line Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Caret_Render_Persistence_And_Non_Goals'Access,
         "No Caret Render Persistence And Non Goals");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Increase_Workflow_Matrix'Access,
         "Indent Increase Workflow Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Outdent_Workflow_And_Whitespace_Matrix'Access,
         "Outdent Workflow And Whitespace Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Clipboard_Line_Edit_Integration'Access,
         "Selection Clipboard Line Edit Integration");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Availability_And_Persistence_Are_Read_Only'Access,
         "Render Availability And Persistence Are Read Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Projects_Canonical_Indentation_Only'Access,
         "Command Palette Projects Canonical Indentation Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keybindings_Reject_Removed_Name_Indentation_Names'Access,
         "Keybindings Reject Removed_Name Indentation Names");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Canonical_Indentation_Path_And_Persistence_Exclusion'Access,
         "Canonical Indentation Path And Persistence Exclusion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Comment_Command_Descriptors'Access,
         "Line Comment Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Comment_Line_Prefix_Matrix_Undo_Redo'Access,
         "Comment Line Prefix Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Uncomment_And_Toggle_Policies'Access,
         "Uncomment And Toggle Policies");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Op_Redo_Empty_And_Active_Buffer_Isolation'Access,
         "No Op Redo Empty And Active Buffer Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indentation_And_Line_Editing_Coexistence'Access,
         "Indentation And Line Editing Coexistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Comment_Edge_Matrix_And_Redo_Preservation'Access,
         "Line Comment Edge Matrix And Redo Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Boundaries_Availability_And_Persistence'Access,
         "Boundaries Availability And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Prefix_Matrix_And_Current_Line_Only'Access,
         "Prefix Matrix And Current Line Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Caret_Selection_Find_Clipboard_Navigation'Access,
         "Caret Selection Find Clipboard Navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Redo_Dirty_And_No_Op_Policy'Access,
         "Redo Dirty And No Op Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indentation_Line_Edit_And_Toggle_Sharing'Access,
         "Indentation Line Edit And Toggle Sharing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Toggle_No_Op_Find_And_Persistence'Access,
         "Completeness Toggle No Op Find And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Read_Only_Routes_And_No_Active_Buffer'Access,
         "Completeness Read Only Routes And No Active Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Line_Boundaries_And_No_Caret'Access,
         "Completeness Line Boundaries And No Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Active_Buffer_Isolation'Access,
         "Completeness Active Buffer Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Comment_Workflow_Matrices'Access,
         "Line Comment Workflow Matrices");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Boundaries_Caret_Selection_And_Find'Access,
         "Line Boundaries Caret Selection And Find");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Line_Edit_Clipboard_And_Redo_Integration'Access,
         "Indent Line Edit Clipboard And Redo Integration");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Read_Only_Routes_Feature_Independence_And_Persistence'Access,
         "Read Only Routes Feature Independence And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keybindings_Reject_Removed_Name_Line_Comment_Names'Access,
         "Keybindings Reject Removed_Name Line Comment Names");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Canonical_Line_Comment_Path_And_Persistence_Exclusion'Access,
         "Canonical Line Comment Path And Persistence Exclusion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Join_Command_Descriptors'Access,
         "Line Join Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Separator_Matrix_Undo_Redo'Access,
         "Join Next Separator Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Boundaries_Redo_And_Caret'Access,
         "Join Next Boundaries Redo And Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Boundaries_Selection_Find_Clipboard_Navigation'Access,
         "Join Next Boundaries Selection Find Clipboard Navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Coexists_With_Line_Edit_Indent_And_Comment'Access,
         "Join Next Coexists With Line Edit Indent And Comment");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Does_Not_Add_Forbidden_Aliases_Or_State'Access,
         "Join Next Does Not Add Forbidden Aliases Or State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Input_Bridge_Route'Access,
         "Join Next Input Bridge Route");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Separator_And_Boundary_Reliability'Access,
         "Join Next Separator And Boundary Reliability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_No_Op_Redo_Dirty_And_Find_Policy'Access,
         "Join Next No Op Redo Dirty And Find Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Caret_Selection_Clipboard_Navigation_And_Render'Access,
         "Join Next Caret Selection Clipboard Navigation And Render");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Mixed_Current_Line_Command_Workflows'Access,
         "Join Next Mixed Current Line Command Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_End_To_End_And_Separator_Workflows'Access,
         "Join Next End To End And Separator Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Caret_Selection_Find_Clipboard_And_Render_Workflow'Access,
         "Join Next Caret Selection Find Clipboard And Render Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Redo_Dirty_And_Mixed_Command_Coexistence'Access,
         "Join Next Redo Dirty And Mixed Command Coexistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Active_Buffer_Routes_Features_And_Persistence'Access,
         "Join Next Active Buffer Routes Features And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Join_Canonical_Cleanup_Surface'Access,
         "Line Join Canonical Cleanup Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Join_Canonical_Behavior_And_Persistence'Access,
         "Line Join Canonical Behavior And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Command_Descriptors_And_Routes'Access,
         "Line Split Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Boundary_Matrix_Undo_Redo'Access,
         "Line Split Boundary Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_State_Boundaries_And_Persistence'Access,
         "Line Split State Boundaries And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_No_Op_Redo_And_Boundaries'Access,
         "Completeness No Op Redo And Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Exact_Position_Matrix'Access,
         "Line Split Exact Position Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Selection_Find_Clipboard_Navigation_And_Render'Access,
         "Line Split Selection Find Clipboard Navigation And Render");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Mixed_Current_Line_Command_Workflows'Access,
         "Line Split Mixed Current Line Command Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Active_Buffer_And_Persistence_Boundaries'Access,
         "Line Split Active Buffer And Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Workflow_Position_And_Boundary_Matrices'Access,
         "Line Split Workflow Position And Boundary Matrices");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Undo_Redo_Dirty_Find_Clipboard_Navigation_Render'Access,
         "Line Split Undo Redo Dirty Find Clipboard Navigation Render");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Mixed_Command_Coexistence_Workflows'Access,
         "Line Split Mixed Command Coexistence Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Active_Buffer_Routes_Features_And_Persistence'Access,
         "Line Split Active Buffer Routes Features And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Selection_Caret_Only_And_Followups'Access,
         "Completeness Selection Caret Only And Followups");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_No_Buffer_No_Caret_And_Routed_Input'Access,
         "Completeness No Buffer No Caret And Routed Input");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Read_Only_And_Persistence_Surfaces'Access,
         "Completeness Read Only And Persistence Surfaces");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Canonical_Surface_Cleanup'Access,
         "Line Split Canonical Surface Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Canonical_Behavior_And_State_Boundaries'Access,
         "Line Split Canonical Behavior And State Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Failure_Read_Only_And_Ordinary_Newline_Separation'Access,
         "Line Split Failure Read Only And Ordinary Newline Separation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Command_Descriptors_And_Routes'Access,
         "Word Delete Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Previous_Word_Boundaries_Selection_And_Undo'Access,
         "Delete Previous Word Boundaries Selection And Undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Next_Word_Boundaries_No_Ops_And_Persistence'Access,
         "Delete Next Word Boundaries No Ops And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Previous_Word_Reliability_Matrix'Access,
         "Delete Previous Word Reliability Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Next_Word_Reliability_Matrix'Access,
         "Delete Next Word Reliability Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_State_Integration_And_Read_Only_Boundaries'Access,
         "Word Delete State Integration And Read Only Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Current_Line_Coexistence_And_Persistence'Access,
         "Word Delete Current Line Coexistence And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Boundary_Transform_Workflows'Access,
         "Word Delete Boundary Transform Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Cross_Line_Selection_Find_Clipboard'Access,
         "Word Delete Cross Line Selection Find Clipboard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Undo_Redo_Dirty_And_Current_Line_Coexistence'Access,
         "Word Delete Undo Redo Dirty And Current Line Coexistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Active_Buffer_Routes_Features_And_Persistence'Access,
         "Word Delete Active Buffer Routes Features And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Canonical_Surface_Cleanup'Access,
         "Word Delete Canonical Surface Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Canonical_Routes_And_State_Boundaries'Access,
         "Word Delete Canonical Routes And State Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Behavior_Preservation_Smoke'Access,
         "Word Delete Behavior Preservation Smoke");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Command_Descriptors_And_Routes'Access,
         "Character Delete Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Previous_Character_Boundaries_Selection_And_Undo'Access,
         "Delete Previous Character Boundaries Selection And Undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Next_Character_Boundaries_No_Ops_And_State'Access,
         "Delete Next Character Boundaries No Ops And State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Completeness_Routes_State_And_Persistence'Access,
         "Character Delete Completeness Routes State And Persistence");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Previous_Reliability_Matrix'Access,
         "Character Delete Previous Reliability Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Next_Reliability_Matrix'Access,
         "Character Delete Next Reliability Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_State_Integration_And_Read_Only_Boundaries'Access,
         "Character Delete State Integration And Read Only Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Mixed_Command_Coexistence_And_Persistence'Access,
         "Character Delete Mixed Command Coexistence And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Boundary_Transform_Workflows'Access,
         "Character Delete Boundary Transform Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_State_Find_Clipboard_Navigation_Render'Access,
         "Character Delete State Find Clipboard Navigation Render");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Mixed_Command_Coexistence_Workflows'Access,
         "Character Delete Mixed Command Coexistence Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Active_Buffer_Routes_And_Persistence'Access,
         "Character Delete Active Buffer Routes And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Canonical_Surface_Cleanup'Access,
         "Character Delete Canonical Surface Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Canonical_Routes_State_And_Persistence'Access,
         "Character Delete Canonical Routes State And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Command_Descriptors_And_Routes'Access,
         "Selection Delete Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Range_Matrix_And_Backward_Selection'Access,
         "Selection Delete Source_Span Matrix And Backward Selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Undo_Redo_Clipboard_Navigation_And_No_Op'Access,
         "Selection Delete Undo Redo Clipboard Navigation And No Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Transform_Matrix_And_Caret'Access,
         "Selection Delete Transform Matrix And Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_No_Op_Invalid_And_Redo_Preservation'Access,
         "Selection Delete No Op Invalid And Redo Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Find_Dirty_Clipboard_And_Navigation'Access,
         "Selection Delete Find Dirty Clipboard And Navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Availability_Render_And_Persistence_Boundaries'Access,
         "Selection Delete Availability Render And Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Active_Buffer_Isolation'Access,
         "Selection Delete Active Buffer Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Selection_Command_And_Edit_Coexistence'Access,
         "Selection Delete Selection Command And Edit Coexistence");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Workflow_Transform_Matrix'Access,
         "Selection Delete Workflow Transform Matrix");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Forward_Backward_Equivalence_And_Invalid_Noops'Access,
         "Forward Backward Equivalence And Invalid Noops");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Undo_Redo_Dirty_Find_Clipboard_And_Navigation_Workflow'Access,
         "Undo Redo Dirty Find Clipboard And Navigation Workflow");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Coexistence_And_Cut_Contrast'Access,
         "Command Coexistence And Cut Contrast");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Read_Only_Routes_Feature_And_Persistence_Boundaries'Access,
         "Read Only Routes Feature And Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Canonical_Surface_Cleanup'Access,
         "Selection Delete Canonical Surface Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Canonical_State_Only_Workflow'Access,
         "Selection Delete Canonical State Only Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Basic_Caret_And_Undo'Access,
         "Text Insert Basic Caret And Undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Replaces_Selection_Without_Clipboard'Access,
         "Text Insert Replaces Selection Without Clipboard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Input_Bridge_Routes_Editor_Text_And_Protects_Overlays'Access,
         "Input Bridge Routes Editor Text And Protects Overlays");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Noop_Invalid_And_Redo_Boundaries'Access,
         "Completeness Noop Invalid And Redo Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Backward_Cross_Line_Replacement_And_Persistence'Access,
         "Completeness Backward Cross Line Replacement And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Unicode_Routing_Internal_Surface_And_Isolation'Access,
         "Completeness Unicode Routing Internal Surface And Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Remove_Removed_Name_Text_Input_Uses_Canonical_Path'Access,
         "Completeness Text Insert Uses Canonical Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Line_Boundary_Command_Is_Canonical_Insert'Access,
         "Completeness Line Boundary Command Is Canonical Insert");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Multi_Caret_Insert_Is_Not_Second_Model'Access,
         "Completeness Multi Caret Insert Is Not Second Model");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Caret_Transform_Matrix'Access,
         "Text Insert Caret Transform Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Replacement_Transform_Matrix'Access,
         "Text Insert Replacement Transform Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Noop_Invalid_And_Redo_Are_NonMutating'Access,
         "Text Insert Noop Invalid And Redo Are NonMutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Invalid_Selection_Does_Not_Repair_State'Access,
         "Text Insert Invalid Selection Does Not Repair State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Find_Clipboard_Navigation_And_Persistence'Access,
         "Text Insert Find Clipboard Navigation And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Active_Buffer_Render_And_Overlay_Routing'Access,
         "Completeness Active Buffer Render And Overlay Routing");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Workflow_Transform_And_Replacement'Access,
         "Text Insert Workflow Transform And Replacement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Noops_Redo_Dirty_And_Find'Access,
         "Text Insert Noops Redo Dirty And Find");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Clipboard_Navigation_Active_Buffer_And_Overlay_Workflow'Access,
         "Text Insert Clipboard Navigation Active Buffer And Overlay Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Mixed_Editing_Features_Render_And_Persistence'Access,
         "Text Insert Mixed Editing Features Render And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Overlay_Owner_Matrix_And_Command_Surface'Access,
         "Text Insert Overlay Owner Matrix And Command Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Canonical_Route_State_And_Persistence'Access,
         "Text Insert Canonical Route State And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Text_Insert_Behavior_Preservation_Smoke'Access,
         "Text Insert Behavior Preservation Smoke");
   end Register_Tests;

end Editor.Line_Edit.Tests;
