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

package body Editor.Line_Edit.Text_Delete_Character_Tests is

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


   procedure Test_Character_Delete_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Character_Delete_Canonical_Routes_State_And_Persistence (T);
   end Test_Character_Delete_Canonical_Surface_Cleanup;

   overriding function Name
     (T : TextDeleteCharacter_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Line_Edit.Text.Delete.Character");
   end Name;

   overriding procedure Register_Tests (T : in out TextDeleteCharacter_Test_Case) is
   begin
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
        (T, Test_Character_Delete_Canonical_Routes_State_And_Persistence'Access,
         "Character Delete Canonical Routes State And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Character_Delete_Canonical_Surface_Cleanup'Access,
         "Character Delete Canonical Surface Cleanup");
   end Register_Tests;

end Editor.Line_Edit.Text_Delete_Character_Tests;
