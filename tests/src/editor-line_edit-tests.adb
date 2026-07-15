with Editor.Test_Temp;
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
      Path   : constant String := Editor.Test_Temp.Base & "/editor-removed-name-line-keybindings";
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

   overriding procedure Register_Tests (T : in out Line_Edit_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Expected_Command_Names_Resolve'Access,
         "Expected Command Names Resolve");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Empty_Buffer_No_Ops'Access,
         "Empty Buffer No Ops");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Last_Line_Move_Down_No_Op_Preserves_Redo_Dirty'Access,
         "Last Line Move Down No Op Preserves Redo Dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clipboard_Selection_Navigation_Boundaries'Access,
         "Clipboard Selection Navigation Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Availability_Has_No_Side_Effects'Access,
         "Availability Has No Side Effects");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Redo_Find_And_Boundary_No_Op_Reliability'Access,
         "Redo Find And Boundary No Op Reliability");

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
        (T, Test_Redo_Find_Selection_Clipboard_And_Navigation_Reliability'Access,
         "Redo Find Selection Clipboard And Navigation Reliability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Caret_Render_Persistence_And_Non_Goals'Access,
         "No Caret Render Persistence And Non Goals");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Availability_And_Persistence_Are_Read_Only'Access,
         "Render Availability And Persistence Are Read Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Op_Redo_Empty_And_Active_Buffer_Isolation'Access,
         "No Op Redo Empty And Active Buffer Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Boundaries_Availability_And_Persistence'Access,
         "Boundaries Availability And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Caret_Selection_Find_Clipboard_Navigation'Access,
         "Caret Selection Find Clipboard Navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Redo_Dirty_And_No_Op_Policy'Access,
         "Redo Dirty And No Op Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Toggle_No_Op_Find_And_Persistence'Access,
         "Completeness Toggle No Op Find And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Read_Only_Routes_And_No_Active_Buffer'Access,
         "Completeness Read Only Routes And No Active Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Active_Buffer_Isolation'Access,
         "Completeness Active Buffer Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Read_Only_Routes_Feature_Independence_And_Persistence'Access,
         "Read Only Routes Feature Independence And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_No_Op_Redo_And_Boundaries'Access,
         "Completeness No Op Redo And Boundaries");
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
        (T, Test_Completeness_Noop_Invalid_And_Redo_Boundaries'Access,
         "Completeness Noop Invalid And Redo Boundaries");

   end Register_Tests;

end Editor.Line_Edit.Tests;
