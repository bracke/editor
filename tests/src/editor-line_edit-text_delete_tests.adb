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

package body Editor.Line_Edit.Text_Delete_Tests is

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
   procedure Test_Selection_Delete_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Selection_Delete_Canonical_State_Only_Workflow (T);
   end Test_Selection_Delete_Canonical_Surface_Cleanup;

   overriding function Name
     (T : TextDelete_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Line_Edit.Text.Delete");
   end Name;
   overriding procedure Register_Tests (T : in out TextDelete_Test_Case) is
   begin
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
        (T, Test_Selection_Delete_Canonical_State_Only_Workflow'Access,
         "Selection Delete Canonical State Only Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_Delete_Canonical_Surface_Cleanup'Access,
         "Selection Delete Canonical Surface Cleanup");
   end Register_Tests;

end Editor.Line_Edit.Text_Delete_Tests;
