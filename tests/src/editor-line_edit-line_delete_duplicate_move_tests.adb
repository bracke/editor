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

package body Editor.Line_Edit.Line_Delete_Duplicate_Move_Tests is

   use type Editor.Keybinding_Config.Keybinding_Config_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Commands.Command_Kind;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Keybindings.Binding_Result;

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

   overriding function Name
     (T : LineDeleteDuplicateMove_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Line_Edit.Line.Delete.Duplicate.Move");
   end Name;

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

   overriding procedure Register_Tests (T : in out LineDeleteDuplicateMove_Test_Case) is
   begin
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
        (T, Test_Delete_First_Last_And_One_Line'Access,
         "Delete First Last And One Line");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Duplicate_Last_Line_Undo_Redo'Access,
         "Duplicate Last Line Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Input_Bridge_Routes_Line_Commands'Access,
         "Input Bridge Routes Line Commands");
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
        (T, Test_Trailing_Newline_Line_Boundaries'Access,
         "Trailing Newline Line Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Duplicate_Move_Workflow_Consistency'Access,
         "Delete Duplicate Move Workflow Consistency");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Terminator_Matrix_Undo_Redo'Access,
         "Line Terminator Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Command_Descriptors'Access,
         "Indent Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Exact_Unit_And_Line_Boundaries'Access,
         "Indent Exact Unit And Line Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Edit_Coexistence_And_Current_Line_Only'Access,
         "Line Edit Coexistence And Current Line Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Clipboard_Line_Edit_Integration'Access,
         "Selection Clipboard Line Edit Integration");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Comment_Command_Descriptors'Access,
         "Line Comment Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Prefix_Matrix_And_Current_Line_Only'Access,
         "Prefix Matrix And Current Line Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indentation_Line_Edit_And_Toggle_Sharing'Access,
         "Indentation Line Edit And Toggle Sharing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Line_Boundaries_And_No_Caret'Access,
         "Completeness Line Boundaries And No Caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Boundaries_Caret_Selection_And_Find'Access,
         "Line Boundaries Caret Selection And Find");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indent_Line_Edit_Clipboard_And_Redo_Integration'Access,
         "Indent Line Edit Clipboard And Redo Integration");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Join_Command_Descriptors'Access,
         "Line Join Command Descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Command_Descriptors_And_Routes'Access,
         "Line Split Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Command_Descriptors_And_Routes'Access,
         "Word Delete Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Current_Line_Coexistence_And_Persistence'Access,
         "Word Delete Current Line Coexistence And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Undo_Redo_Dirty_And_Current_Line_Coexistence'Access,
         "Word Delete Undo Redo Dirty And Current Line Coexistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Command_Descriptors_And_Routes'Access,
         "Character Delete Command Descriptors And Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Command_Descriptors_And_Routes'Access,
         "Selection Delete Command Descriptors And Routes");
   end Register_Tests;

end Editor.Line_Edit.Line_Delete_Duplicate_Move_Tests;
