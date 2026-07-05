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

package body Editor.Line_Edit.Text_Insert_Tests is

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

   overriding function Name
     (T : TextInsert_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Line_Edit.Text.Insert");
   end Name;

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

   overriding procedure Register_Tests (T : in out TextInsert_Test_Case) is
   begin
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
        (T, Test_Completeness_Backward_Cross_Line_Replacement_And_Persistence'Access,
         "Completeness Backward Cross Line Replacement And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Completeness_Unicode_Routing_Internal_Surface_And_Isolation'Access,
         "Completeness Unicode Routing Internal Surface And Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Remove_Removed_Name_Text_Input_Uses_Canonical_Path'Access,
         "Completeness Text Insert Uses Canonical Path");
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

end Editor.Line_Edit.Text_Insert_Tests;
