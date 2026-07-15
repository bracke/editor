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

package body Editor.Line_Edit.Text_Delete_Word_Tests is

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
      Path           : constant String := Editor.Test_Temp.Base & "/editor-canonical-word-delete-keybindings";
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

   overriding function Name
     (T : TextDeleteWord_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Line_Edit.Text.Delete.Word");
   end Name;

   overriding procedure Register_Tests (T : in out TextDeleteWord_Test_Case) is
   begin
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
        (T, Test_Word_Delete_Boundary_Transform_Workflows'Access,
         "Word Delete Boundary Transform Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Delete_Cross_Line_Selection_Find_Clipboard'Access,
         "Word Delete Cross Line Selection Find Clipboard");
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
   end Register_Tests;

end Editor.Line_Edit.Text_Delete_Word_Tests;
