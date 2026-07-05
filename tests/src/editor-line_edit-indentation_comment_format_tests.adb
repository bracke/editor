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

package body Editor.Line_Edit.Indentation_Comment_Format_Tests is

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

   procedure Test_Indent_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class);

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

   overriding function Name
     (T : IndentationCommentFormat_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Line_Edit.Indentation.Comment.Format");
   end Name;

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

   overriding procedure Register_Tests (T : in out IndentationCommentFormat_Test_Case) is
   begin
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
        (T, Test_Indent_Increase_Workflow_Matrix'Access,
         "Indent Increase Workflow Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Outdent_Workflow_And_Whitespace_Matrix'Access,
         "Outdent Workflow And Whitespace Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Comment_Line_Prefix_Matrix_Undo_Redo'Access,
         "Comment Line Prefix Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Uncomment_And_Toggle_Policies'Access,
         "Uncomment And Toggle Policies");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indentation_And_Line_Editing_Coexistence'Access,
         "Indentation And Line Editing Coexistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Comment_Edge_Matrix_And_Redo_Preservation'Access,
         "Line Comment Edge Matrix And Redo Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Comment_Workflow_Matrices'Access,
         "Line Comment Workflow Matrices");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Canonical_Line_Comment_Path_And_Persistence_Exclusion'Access,
         "Canonical Line Comment Path And Persistence Exclusion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Join_Next_Coexists_With_Line_Edit_Indent_And_Comment'Access,
         "Join Next Coexists With Line Edit Indent And Comment");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Trim_Trailing_Whitespace_Command_Surface'Access,
         "Trim Trailing Whitespace Command Surface");
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
        (T, Test_Command_Palette_Projects_Canonical_Indentation_Only'Access,
         "Command Palette Projects Canonical Indentation Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keybindings_Reject_Removed_Name_Indentation_Names'Access,
         "Keybindings Reject Removed_Name Indentation Names");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Canonical_Indentation_Path_And_Persistence_Exclusion'Access,
         "Canonical Indentation Path And Persistence Exclusion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keybindings_Reject_Removed_Name_Line_Comment_Names'Access,
         "Keybindings Reject Removed_Name Line Comment Names");
   end Register_Tests;

end Editor.Line_Edit.Indentation_Comment_Format_Tests;
