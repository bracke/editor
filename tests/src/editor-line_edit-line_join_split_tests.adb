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

package body Editor.Line_Edit.Line_Join_Split_Tests is

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

   overriding function Name
     (T : LineJoinSplit_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Line_Edit.Line.Join.Split");
   end Name;

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

   overriding procedure Register_Tests (T : in out LineJoinSplit_Test_Case) is
   begin
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
        (T, Test_Line_Join_Canonical_Behavior_And_Persistence'Access,
         "Line Join Canonical Behavior And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Boundary_Matrix_Undo_Redo'Access,
         "Line Split Boundary Matrix Undo Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_State_Boundaries_And_Persistence'Access,
         "Line Split State Boundaries And Persistence");
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
        (T, Test_Line_Split_Canonical_Behavior_And_State_Boundaries'Access,
         "Line Split Canonical Behavior And State Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Failure_Read_Only_And_Ordinary_Newline_Separation'Access,
         "Line Split Failure Read Only And Ordinary Newline Separation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Line_Boundary_Command_Is_Canonical_Insert'Access,
         "Completeness Line Boundary Command Is Canonical Insert");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Join_Canonical_Cleanup_Surface'Access,
         "Line Join Canonical Cleanup Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Line_Split_Canonical_Surface_Cleanup'Access,
         "Line Split Canonical Surface Cleanup");
   end Register_Tests;

end Editor.Line_Edit.Line_Join_Split_Tests;
