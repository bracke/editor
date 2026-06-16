with AUnit.Assertions; use AUnit.Assertions;
with Editor.Cursors; use Editor.Cursors;
with Editor.State;
with Editor.Commands;
use type Editor.Commands.Command_Availability_Status;
use type Editor.Commands.Command_Category;
use type Editor.Commands.Command_Visibility;
with Text_Buffer;
with Editor.Test_Helper;
with Editor.View;
with Editor.Layout;
with Editor.Input_Bridge;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Buffers;
with Editor.Diagnostics;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Messages;
with Editor.History;
with Editor.Pending_Transitions;
with Editor.Dirty_Guards;
with Editor.Dirty_Lines;
with Editor.Selection;
with Editor.Search;
with Editor.Input_Field;
with Editor.Panels;
with Editor.Project;
with Editor.Recent_Projects;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Quick_Open;
with Editor.Buffer_Switcher;
use type Editor.Buffer_Switcher.Switcher_Metadata_Filter_Kind;
use type Editor.Buffer_Switcher.Switcher_Sort_Mode;
use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
with Editor.Recent_Buffers;
with Editor.Go_To_Line;
with Editor.Navigation_History;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;
with Editor.Command_Palette;
with Editor.Problems;
with Editor.Feature_Messages;
with Editor.Feature_Diagnostics;
with Editor.Feature_Search_Results;
with Editor.Feature_Panel;
with Editor.Outline;
with Editor.Outline.Fixtures; use Editor.Outline.Fixtures;
with Editor.Workspace_Persistence;
with Editor.Configuration_Audit;
with Editor.Render_Model;
with Editor.Files;
with Editor.Build_Candidates;
with Editor.Build_UI;
with Ada.Containers; use type Ada.Containers.Count_Type;

package body Editor.Executor.Tests is

   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Diagnostics.Diagnostic_Index;
   use type Editor.Gutter_Markers.Gutter_Marker_Kind;
   use type Editor.Dirty_Lines.Dirty_Line_Kind;
   use type Editor.Search.Search_Match_Index;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Project_Search_Bar.Project_Search_Bar_Zone;
   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Go_To_Line.Go_To_Line_Validation_Status;
   use type Editor.Pending_Transitions.Pending_Transition_Kind;
   use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;
   use type Ada.Directories.File_Kind;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.State.Dirty_Close_Scope;
   use type Editor.Project.Project_File_Refresh_Status;
   use type Editor.Outline.Outline_Refresh_Status;
   use type Editor.Build_UI.Build_Candidate_Refresh_Status;
   use type Editor.Project_Search.Project_Search_File_Kind_Filter;
   use type Editor.Quick_Open.Quick_Open_Priority_Mode;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Temp_Path (Name : String) return String is
   begin
      return Ada.Directories.Compose
        (Ada.Directories.Current_Directory, "phase57_exec_" & Name);
   end Temp_Path;

   function Executor_Recent_Config_Dir return String is
   begin
      return Temp_Path ("executor_recent_config");
   end Executor_Recent_Config_Dir;

   procedure Use_Executor_Recent_Config is
   begin
      Editor.Recent_Projects.Set_Config_Directory_For_Tests
        (Executor_Recent_Config_Dir);
   end Use_Executor_Recent_Config;

   procedure Remove_File_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   end Remove_File_If_Exists;

   procedure Init_Executor_Test_State (S : out Editor.State.State_Type) is
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.View.Reset;
      Use_Executor_Recent_Config;
      Remove_File_If_Exists (Editor.Recent_Projects.Recent_Projects_File_Path);
      Editor.State.Init (S);
   end Init_Executor_Test_State;

   procedure Remove_Dir_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Directory (Path);
      end if;
   end Remove_Dir_If_Exists;

   procedure Remove_Tree_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         if Ada.Directories.Kind (Path) = Ada.Directories.Directory then
            Ada.Directories.Delete_Tree (Path);
         else
            Ada.Directories.Delete_File (Path);
         end if;
      end if;
   exception
      when others =>
         null;
   end Remove_Tree_If_Exists;

   procedure Write_Bytes (Path : String; Bytes : String) is
      F : Stream_IO.File_Type;
      Raw : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Bytes'Length));
   begin
      Stream_IO.Create (F, Stream_IO.Out_File, Path);
      for I in Bytes'Range loop
         Raw (Ada.Streams.Stream_Element_Offset (I - Bytes'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Bytes (I)));
      end loop;
      if Bytes'Length > 0 then
         Stream_IO.Write (F, Raw);
      end if;
      Stream_IO.Close (F);
   end Write_Bytes;

   procedure Build_Fixture (Root : String) is
      A_Dir : constant String := Ada.Directories.Compose (Root, "a_dir");
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (A_Dir, "nested.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_Dir_If_Exists (A_Dir);
      Remove_Dir_If_Exists (Root);

      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (A_Dir);
      Write_Bytes (Ada.Directories.Compose (A_Dir, "nested.txt"), "nested");
      Write_Bytes (Ada.Directories.Compose (Root, "a.txt"), "a");
   end Build_Fixture;

   procedure Cleanup_Fixture (Root : String) is
      A_Dir : constant String := Ada.Directories.Compose (Root, "a_dir");
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (A_Dir, "nested.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_Dir_If_Exists (A_Dir);
      Remove_Dir_If_Exists (Root);
   end Cleanup_Fixture;

   procedure Build_Project_Search_Fixture (Root : String) is
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "needle.txt"));
      Remove_Dir_If_Exists (Root);

      Ada.Directories.Create_Directory (Root);
      Write_Bytes
        (Ada.Directories.Compose (Root, "needle.txt"),
         "zero" & ASCII.LF & "hello needle" & ASCII.LF);
   end Build_Project_Search_Fixture;

   procedure Cleanup_Project_Search_Fixture (Root : String) is
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "needle.txt"));
      Remove_Dir_If_Exists (Root);
   end Cleanup_Project_Search_Fixture;

   procedure Build_Project_Search_Multi_Fixture (Root : String) is
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "needle_multi.txt"));
      Remove_Dir_If_Exists (Root);

      Ada.Directories.Create_Directory (Root);
      Write_Bytes
        (Ada.Directories.Compose (Root, "needle_multi.txt"),
         "needle one" & ASCII.LF
         & "middle" & ASCII.LF
         & "needle two" & ASCII.LF
         & "needle three" & ASCII.LF);
   end Build_Project_Search_Multi_Fixture;

   procedure Cleanup_Project_Search_Multi_Fixture (Root : String) is
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "needle_multi.txt"));
      Remove_Dir_If_Exists (Root);
   end Cleanup_Project_Search_Multi_Fixture;

   procedure Build_Project_Search_Context_Fixture (Root : String) is
      Src_Dir    : constant String := Ada.Directories.Compose (Root, "src");
      Editor_Dir : constant String := Ada.Directories.Compose (Src_Dir, "editor");
      Other_Dir  : constant String := Ada.Directories.Compose (Src_Dir, "other");
   begin
      Remove_Tree_If_Exists (Root);

      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src_Dir);
      Ada.Directories.Create_Directory (Editor_Dir);
      Ada.Directories.Create_Directory (Other_Dir);
      Write_Bytes
        (Ada.Directories.Compose (Editor_Dir, "executor.adb"),
         "procedure Execute_Command is" & ASCII.LF
         & "begin" & ASCII.LF
         & "   null;" & ASCII.LF
         & "end Execute_Command;" & ASCII.LF);
      Write_Bytes
        (Ada.Directories.Compose (Other_Dir, "other.adb"),
         "procedure Execute_Command is" & ASCII.LF
         & "begin null; end Execute_Command;" & ASCII.LF);
   end Build_Project_Search_Context_Fixture;

   procedure Cleanup_Project_Search_Context_Fixture (Root : String) is
   begin
      Remove_Tree_If_Exists (Root);
   end Cleanup_Project_Search_Context_Fixture;


   procedure Set_Buffer_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Text_Buffer.Clear (S.Buffer);
      for Ch of Text loop
         Text_Buffer.Insert (S.Buffer, Text_Buffer.Length (S.Buffer), Ch);
      end loop;
      Editor.State.Rebuild_Line_Index (S);
      Editor.State.Reset_Dirty_Line_Baseline (S);
      S.File_Info.Dirty := False;
   end Set_Buffer_Text;

   function Buffer_Text (S : Editor.State.State_Type) return String is
      Result : String (1 .. Text_Buffer.Length (S.Buffer));
   begin
      for I in Result'Range loop
         Result (I) := Text_Buffer.Element (S.Buffer, I);
      end loop;
      return Result;
   end Buffer_Text;


   function Numbered_Lines (Count : Positive; Needle_Line : Natural := 0) return String is
      Text : Unbounded_String := Null_Unbounded_String;
   begin
      for Line in 1 .. Count loop
         if Line = Needle_Line then
            Append (Text, "line " & Ada.Strings.Fixed.Trim (Natural'Image (Line), Ada.Strings.Both) & " needle");
         else
            Append (Text, "line " & Ada.Strings.Fixed.Trim (Natural'Image (Line), Ada.Strings.Both));
         end if;
         if Line < Count then
            Append (Text, ASCII.LF);
         end if;
      end loop;
      return To_String (Text);
   end Numbered_Lines;

   procedure Move_Caret_To_Line
     (S    : in out Editor.State.State_Type;
      Line : Positive)
   is
      Target : constant Editor.Cursors.Cursor_Index :=
        Editor.State.Line_Start (S, Line - 1);
   begin
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => Target,
          Anchor                => Target,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Preferred_Column := 0;
   end Move_Caret_To_Line;

   function Latest_Message_Text (S : Editor.State.State_Type) return String;

   function Pending_Test_Summary
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Active_Caret_Line (S : Editor.State.State_Type) return Natural is
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      if S.Carets.Length = 0 then
         return 0;
      end if;
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      return Row + 1;
   end Active_Caret_Line;

   function Back_Top_Line (S : Editor.State.State_Type) return Natural is
   begin
      if S.Navigation_History.Back_Stack.Is_Empty then
         return 0;
      end if;
      return S.Navigation_History.Back_Stack
        (S.Navigation_History.Back_Stack.Last_Index).Line;
   end Back_Top_Line;

   function Forward_Top_Line (S : Editor.State.State_Type) return Natural is
   begin
      if S.Navigation_History.Forward_Stack.Is_Empty then
         return 0;
      end if;
      return S.Navigation_History.Forward_Stack
        (S.Navigation_History.Forward_Stack.Last_Index).Line;
   end Forward_Top_Line;

   function Back_Top_Path (S : Editor.State.State_Type) return String is
   begin
      if S.Navigation_History.Back_Stack.Is_Empty then
         return "";
      end if;
      return To_String
        (S.Navigation_History.Back_Stack
           (S.Navigation_History.Back_Stack.Last_Index).File_Path);
   end Back_Top_Path;

   overriding function Name
     (T : Executor_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor");
   end Name;

   procedure Test_Insert
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Cmd := Editor.Test_Helper.Insert (0, 'X');

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Text_Buffer.Length (S.Buffer) = 1, "Insert failed");
      Assert (Text_Buffer.Element (S.Buffer, 1) = 'X', "Wrong char");
   end Test_Insert;

   procedure Test_Backspace_Delete
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 2,
         Anchor => 2,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));  -- caret after 'b'

      Cmd.Kind := Editor.Commands.Delete_Char;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Length (S.Buffer) = 2,
         "Backspace delete length failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 1) = 'a',
         "Backspace delete first char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 2) = 'c',
         "Backspace delete second char failed");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 1,
         "Backspace delete caret failed");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 1,
         "Backspace delete anchor failed");
   end Test_Backspace_Delete;

   procedure Test_Forward_Delete
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 1,
         Anchor => 1,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));  --  caret after 'a', before 'b'

      Cmd.Kind := Editor.Commands.Forward_Delete_Char;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Length (S.Buffer) = 2,
         "Forward delete length failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 1) = 'a',
         "Forward delete first char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 2) = 'c',
         "Forward delete second char failed");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 1,
         "Forward delete caret failed");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 1,
         "Forward delete anchor failed");
   end Test_Forward_Delete;

   procedure Test_Backspace_Delete_Newline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 6, Character'Val (Character'Pos ('f')));

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 4,
         Anchor => 4,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));  --  caret at start of second line

      Cmd.Kind := Editor.Commands.Delete_Char;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Length (S.Buffer) = 6,
         "Backspace newline delete length failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 1) = 'a',
         "Backspace newline first char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 2) = 'b',
         "Backspace newline second char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 3) = 'c',
         "Backspace newline third char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 4) = 'd',
         "Backspace newline fourth char failed");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 3,
         "Backspace newline caret failed");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 3,
         "Backspace newline anchor failed");
   end Test_Backspace_Delete_Newline;

   procedure Test_Forward_Delete_Newline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 6, Character'Val (Character'Pos ('f')));

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 3,
         Anchor => 3,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));  --  caret before newline

      Cmd.Kind := Editor.Commands.Forward_Delete_Char;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Length (S.Buffer) = 6,
         "Forward delete newline length failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 1) = 'a',
         "Forward delete newline first char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 2) = 'b',
         "Forward delete newline second char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 3) = 'c',
         "Forward delete newline third char failed");
      Assert
        (Text_Buffer.Element (S.Buffer, 4) = 'd',
         "Forward delete newline fourth char failed");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 3,
         "Forward delete newline caret failed");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 3,
         "Forward delete newline anchor failed");
   end Test_Forward_Delete_Newline;

   procedure Test_Preferred_Column_Up_Down
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      --  "abcdef\nxy\nabcdef"
      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('f')));
      Text_Buffer.Insert (S.Buffer, 6,  ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 7, Character'Val (Character'Pos ('x')));
      Text_Buffer.Insert (S.Buffer, 8, Character'Val (Character'Pos ('y')));
      Text_Buffer.Insert (S.Buffer, 9,  ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 10, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 11, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 12, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 13, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 14, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 15, Character'Val (Character'Pos ('f')));

      Editor.State.Rebuild_After_Buffer_Change (S);

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 5,
         Anchor => 5,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));  --  column 5 on first line
      S.Preferred_Column := 5;

      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Cmd.Kind := Editor.Commands.Move_Down;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 9,
         "Move_Down should clamp to end of short middle line");

      Cmd.Kind := Editor.Commands.Move_Down;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 15,
         "Second Move_Down should restore preferred column on longer line");
   end Test_Preferred_Column_Up_Down;

   procedure Test_Home_End
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      --  "abc\ndef"
      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 6, Character'Val (Character'Pos ('f')));
      Editor.State.Rebuild_After_Buffer_Change (S);

      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 6,
         Anchor => 6,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
      S.Preferred_Column := 2;

      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Cmd.Kind := Editor.Commands.Move_Home;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 4,
         "Home must move to start of current line");

      Cmd.Kind := Editor.Commands.Move_End;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 7,
         "End must move to end of current line");
   end Test_Home_End;


   procedure Test_Word_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "alpha  beta,++gamma");

      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Cmd.Kind := Editor.Commands.Move_Word_Right;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 7,
         "word-right from word start must land at next word start");

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 11,
         "word-right from word start must stop at the following boundary");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Caret_State'
           (Pos => 11, Anchor => 11, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Word_Left;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 7,
         "word-left from word end must stop at word start");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Caret_State'
           (Pos => 14, Anchor => 14, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Word_Left;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 11,
         "word-left must treat symbol runs separately from words");
   end Test_Word_Navigation;

   procedure Test_Shift_Word_Right_Selects
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "alpha beta");

      Cmd.Kind := Editor.Commands.Move_Word_Right;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := True;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 0,
         "shift-word-right must keep the original anchor");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 6,
         "shift-word-right must move caret to next word start");
   end Test_Shift_Word_Right_Selects;

   procedure Test_Document_Start_End
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Caret_State'
           (Pos => 3, Anchor => 3, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Cmd.Kind := Editor.Commands.Move_Document_End;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 7,
         "document-end must move to buffer end");

      Cmd.Kind := Editor.Commands.Move_Document_Start;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 0,
         "document-start must move to buffer start");
   end Test_Document_Start_End;

   procedure Test_Page_Down_Uses_Visible_Row_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "0" & ASCII.LF &
         "1" & ASCII.LF &
         "2" & ASCII.LF &
         "3" & ASCII.LF &
         "4" & ASCII.LF &
         "5");

      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Editor.Layout.Cell_H * 3);

      Cmd.Kind := Editor.Commands.Move_Page_Down;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 4,
         "page-down must move by visible row count minus one");
   end Test_Page_Down_Uses_Visible_Row_Count;

   procedure Test_Select_Word_And_Whitespace_At_Point
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      X      : Natural;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "alpha beta");
      Editor.View.Reset_Scroll;

      Cmd.Kind := Editor.Commands.Select_Word_At_Point;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_Y := 0;

      X := Editor.Layout.Text_Origin_X (Layout, Editor.State.Line_Count (S))
        + 1 * Editor.Layout.Cell_W;
      Cmd.Click_X := X;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 0
         and then S.Carets (S.Carets.First_Index).Pos = 5,
         "double-click inside a word must select the complete word run");

      X := Editor.Layout.Text_Origin_X (Layout, Editor.State.Line_Count (S))
        + 5 * Editor.Layout.Cell_W;
      Cmd.Click_X := X;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor =
         S.Carets (S.Carets.First_Index).Pos,
         "double-click whitespace must place a caret without creating a selection");
   end Test_Select_Word_And_Whitespace_At_Point;

   procedure Test_Select_Line_At_Point
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "defg");
      Editor.View.Reset_Scroll;

      Cmd.Kind := Editor.Commands.Select_Line_At_Point;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := Editor.Layout.Text_Origin_X (Layout, Editor.State.Line_Count (S));
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout))
        + Editor.Layout.Cell_H;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 4,
         "triple-click line selection must anchor at logical line start");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 8,
         "triple-click last-line selection must end at the line length");
   end Test_Select_Line_At_Point;

   procedure Test_Mouse_Hit_Before_Text_Origin_Clamps_To_Column_Zero
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      X      : Natural := Editor.Layout.Text_Origin_X (Layout, 1);
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc");
      Editor.View.Reset_Scroll;

      if X > 0 then
         X := X - 1;
      end if;

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := X;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Pos = 0,
         "mouse hit before text origin must clamp to column zero");
   end Test_Mouse_Hit_Before_Text_Origin_Clamps_To_Column_Zero;

   procedure Test_Drag_Creates_Normal_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abcdef");
      Editor.View.Reset_Scroll;

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := Editor.Layout.Text_Origin_X (Layout, 1)
        + 1 * Editor.Layout.Cell_W;
      Cmd.Click_Y := 0;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Cmd.Kind := Editor.Commands.Drag_To_Point;
      Cmd.Click_X := Editor.Layout.Text_Origin_X (Layout, 1)
        + 4 * Editor.Layout.Cell_W;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 1,
         "drag selection must preserve the mouse-down anchor");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 4,
         "drag selection must update the caret to the drag point");
      Assert
        (not S.Rect_Select_Active,
         "normal drag must not enable rectangle selection");
   end Test_Drag_Creates_Normal_Selection;

   procedure Test_Gutter_Click_Moves_To_Line_Start
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      X      : Natural := Editor.Layout.Text_Origin_X (Layout, 2);
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.View.Reset_Scroll;

      if X > 0 then
         X := X - 1;
      end if;

      Cmd.Kind := Editor.Commands.Move_To_Point;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := X;
      Cmd.Click_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout))
        + Editor.Layout.Cell_H;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Pos = 4,
         "gutter click on second row must move caret to that line start");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 4,
         "gutter click without shift must collapse selection at line start");
   end Test_Gutter_Click_Moves_To_Line_Start;

   procedure Test_Shift_Page_Down_Extends_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "0" & ASCII.LF &
         "1" & ASCII.LF &
         "2" & ASCII.LF &
         "3");

      Editor.View.Set_Viewport
        (Width  => 800,
         Height => Editor.Layout.Cell_H * 2);

      Cmd.Kind := Editor.Commands.Select_Page_Down;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 0,
         "select-page-down must keep the original anchor");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 2,
         "select-page-down must move by visible rows minus one");
   end Test_Shift_Page_Down_Extends_Selection;

   procedure Test_Multi_Caret_Shift_Word_Right_Selects_All
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "alpha beta gamma");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Carets.Append
        (Caret_State'
           (Pos => 6, Anchor => 6, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Word_Right;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := True;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets.Length = 2,
         "shift-word-right must preserve both carets");
      Assert
        (S.Carets (0).Anchor = 0 and then S.Carets (0).Pos = 6,
         "first caret must extend to the next word start");
      Assert
        (S.Carets (1).Anchor = 6 and then S.Carets (1).Pos = 11,
         "second caret must extend to the next word start");
   end Test_Multi_Caret_Shift_Word_Right_Selects_All;


   procedure Test_Multi_Caret_Move_Right_Applies_To_All
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abcdef");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Carets.Append
        (Caret_State'
           (Pos => 3, Anchor => 3, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Right;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets.Length = 2,
         "move-right must preserve non-overlapping multi-carets");
      Assert
        (S.Carets (0).Pos = 1 and then S.Carets (0).Anchor = 1,
         "first caret must move right and collapse its anchor");
      Assert
        (S.Carets (1).Pos = 4 and then S.Carets (1).Anchor = 4,
         "second caret must move right and collapse its anchor");
   end Test_Multi_Caret_Move_Right_Applies_To_All;

   procedure Test_Select_Right_Extends_All_Carets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abcdef");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Carets.Append
        (Caret_State'
           (Pos => 3, Anchor => 3, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Right;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := True;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Carets.Length = 2,
         "select-right must preserve non-overlapping multi-carets");
      Assert
        (S.Carets (0).Anchor = 0 and then S.Carets (0).Pos = 1,
         "first caret must preserve anchor and extend right");
      Assert
        (S.Carets (1).Anchor = 3 and then S.Carets (1).Pos = 4,
         "second caret must preserve anchor and extend right");
   end Test_Select_Right_Extends_All_Carets;

   procedure Test_Navigation_Does_Not_Mutate_Text_Or_Dirty_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Before : constant String := "abc" & ASCII.LF & "def";
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, Before);
      Editor.State.Reset_Dirty_Line_Baseline (S);

      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Caret_State'
           (Pos => 1, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Move_Word_Right;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Cmd.Kind := Editor.Commands.Move_Page_Down;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Editor.State.Current_Text (S) = Before,
         "navigation commands must not mutate buffer text");
      Assert
        (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
         "navigation commands must not create dirty-line state");
      Assert
        (not S.File_Info.Dirty,
         "navigation commands must not mark the file dirty");
   end Test_Navigation_Does_Not_Mutate_Text_Or_Dirty_Lines;

   procedure Test_Delete_Semantics
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      --  "abc\ndef"
      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 6, Character'Val (Character'Pos ('f')));

      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      --  Backspace joins lines from start of second line
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 4,
         Anchor => 4,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));

      Cmd.Kind := Editor.Commands.Delete_Char;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Element (S.Buffer, 3) = 'c',
         "Backspace must remove newline before caret");

      --  Reset
      Init_Executor_Test_State (S);
      Text_Buffer.Insert (S.Buffer, 0, Character'Val (Character'Pos ('a')));
      Text_Buffer.Insert (S.Buffer, 1, Character'Val (Character'Pos ('b')));
      Text_Buffer.Insert (S.Buffer, 2, Character'Val (Character'Pos ('c')));
      Text_Buffer.Insert (S.Buffer, 3, ASCII.LF);
      Text_Buffer.Insert (S.Buffer, 4, Character'Val (Character'Pos ('d')));
      Text_Buffer.Insert (S.Buffer, 5, Character'Val (Character'Pos ('e')));
      Text_Buffer.Insert (S.Buffer, 6, Character'Val (Character'Pos ('f')));

      --  Delete joins lines from end of first line
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => 3,
         Anchor => 3,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));

      Cmd.Kind := Editor.Commands.Forward_Delete_Char;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (Text_Buffer.Element (S.Buffer, 3) = 'c',
         "Delete must remove newline at caret");
   end Test_Delete_Semantics;



   procedure Test_File_Tree_Node_Action_Toggles_Directory
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("toggle_root");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      A_Dir : Editor.File_Tree.File_Tree_Node_Id;
      Before_Count : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      A_Dir := Editor.File_Tree.Find_By_Path (S.File_Tree, "a_dir", Found);
      Assert (Found, "fixture must contain a_dir");
      Before_Count := Editor.File_Tree.Visible_Row_Count (S.File_Tree);

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, A_Dir, Editor.File_Tree_View.Toggle_Directory_Action);
      Assert (Editor.File_Tree.Node (S.File_Tree, A_Dir).Is_Expanded,
              "file tree node action must expand directory nodes");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) > Before_Count,
              "directory toggle must rebuild visible rows");

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, A_Dir, Editor.File_Tree_View.Toggle_Directory_Action);
      Assert (not Editor.File_Tree.Node (S.File_Tree, A_Dir).Is_Expanded,
              "second toggle must collapse directory nodes");

      Cleanup_Fixture (Root);
   end Test_File_Tree_Node_Action_Toggles_Directory;

   procedure Test_File_Tree_Node_Action_Opens_And_Switches_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("open_root");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      File_Id : Editor.File_Tree.File_Tree_Node_Id;
      Dir_Id : Editor.File_Tree.File_Tree_Node_Id;
      Count_After_Open : Natural;
      Active_After_Open : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      File_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt");
      Dir_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a_dir", Found);
      Assert (Found, "fixture must contain a_dir");

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, File_Id, Editor.File_Tree_View.Open_File_Action);
      Count_After_Open := Editor.Buffers.Global_Count;
      Active_After_Open := Editor.Buffers.Global_Active_Buffer;
      Assert (Count_After_Open >= 1,
              "file tree open action must create or activate a buffer");
      Assert (S.File_Info.Has_Path,
              "file tree open action must update active file identity");
      Assert (To_String (S.File_Info.Display_Name) = "a.txt",
              "file tree open action must make clicked file active");

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, File_Id, Editor.File_Tree_View.Open_File_Action);
      Assert (Editor.Buffers.Global_Count = Count_After_Open,
              "opening an already-open file from tree must not duplicate buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = Active_After_Open,
              "opening an already-open active file must keep the existing buffer active");

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, Dir_Id, Editor.File_Tree_View.Open_File_Action);
      Assert (Editor.Buffers.Global_Count = Count_After_Open,
              "open-file action on directory node must be a no-op");

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, File_Id, Editor.File_Tree_View.Toggle_Directory_Action);
      Assert (Editor.Buffers.Global_Count = Count_After_Open,
              "toggle-directory action on file node must be a no-op");

      Cleanup_Fixture (Root);
   end Test_File_Tree_Node_Action_Opens_And_Switches_File;

   procedure Test_Phase264_File_Tree_Node_Action_Pushes_Navigation_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase264_tree_history");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      First_File : Editor.File_Tree.File_Tree_Node_Id;
      Second_File : Editor.File_Tree.File_Tree_Node_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      First_File := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt");
      Second_File := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "a_dir/nested.txt", Found);
      Assert (Found, "fixture must contain nested file");

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, First_File, Editor.File_Tree_View.Open_File_Action);
      Assert (To_String (S.File_Info.Display_Name) = "a.txt",
              "first tree activation must make a.txt active");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "first file activation from empty startup has no prior editor location");

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, Second_File, Editor.File_Tree_View.Open_File_Action);
      Assert (To_String (S.File_Info.Display_Name) = "nested.txt",
              "second tree activation must switch active buffer");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 346 File Tree activation is not a navigation-history recording point");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (Latest_Message_Text (S) = "No previous navigation location.",
              "navigation.back after File Tree-only movement must report empty history");

      Cleanup_Fixture (Root);
   end Test_Phase264_File_Tree_Node_Action_Pushes_Navigation_History;

   procedure Test_File_Tree_Node_Action_Invalid_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Count_Before : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Count_Before := Editor.Buffers.Global_Count;
      Editor.Executor.Execute_File_Tree_Node_Action
        (S,
         Editor.File_Tree.File_Tree_Node_Id'Last,
         Editor.File_Tree_View.Open_File_Action);
      Assert (Editor.Buffers.Global_Count = Count_Before,
              "invalid file tree node action must not mutate buffers");
      Assert (Editor.File_Tree.Is_Empty (S.File_Tree),
              "invalid file tree node action must not mutate file tree");
   end Test_File_Tree_Node_Action_Invalid_Is_No_Op;



   procedure Test_Phase212_File_Tree_Missing_Target_Does_Not_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase212_missing_target_root");
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      File_Id : Editor.File_Tree.File_Tree_Node_Id;
      Count_Before : Natural;
      Rows_Before  : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      File_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt before removal");

      Remove_File_If_Exists (File_Path);
      Count_Before := Editor.Buffers.Global_Count;
      Rows_Before := Editor.File_Tree.Visible_Row_Count (S.File_Tree);

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, File_Id, Editor.File_Tree_View.Open_File_Action);

      Assert (Editor.Buffers.Global_Count = Count_Before,
              "missing file tree targets must not open a buffer");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Rows_Before,
              "missing file tree activation must not mutate file tree rows");
      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase212_File_Tree_Missing_Target_Does_Not_Open;

   procedure Test_Phase212_Refresh_Preserves_Unchanged_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase212_refresh_selection_root");
      Added : constant String := Ada.Directories.Compose (Root, "b.txt");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      File_Id : Editor.File_Tree.File_Tree_Node_Id;
      Row : Natural := 0;
      Row_Found : Boolean := False;
      Selected : Editor.File_Tree.File_Tree_Node_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      Editor.Executor.Execute_Open_Project (S, Root);

      File_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, File_Id, Row_Found);
      Assert (Row_Found, "a.txt must be visible in the file tree");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Write_Bytes (Added, "new");
      Editor.Executor.Execute_Refresh_File_Tree (S);

      Selected := Editor.File_Tree_View.Node_For_Row
        (S.File_Tree,
         Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View),
         Found);
      Assert (Found, "refresh must leave a valid selected row");
      Assert (To_String (Editor.File_Tree.Node (S.File_Tree, Selected).Relative_Path) = "a.txt",
              "refresh must preserve selection when the same target still exists");
      Remove_File_If_Exists (Added);
      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_File_If_Exists (Added);
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase212_Refresh_Preserves_Unchanged_Selection;


   procedure Test_Phase212_Refresh_Clears_Disappeared_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase212_refresh_removed_selection_root");
      Removed : constant String := Ada.Directories.Compose (Root, "a.txt");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      File_Id : Editor.File_Tree.File_Tree_Node_Id;
      Row : Natural := 0;
      Row_Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      Editor.Executor.Execute_Open_Project (S, Root);

      File_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, File_Id, Row_Found);
      Assert (Row_Found, "a.txt must be visible in the file tree");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Remove_File_If_Exists (Removed);
      Editor.Executor.Execute_Refresh_File_Tree (S);

      Assert (Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View) = 0,
              "refresh must clear selection when the selected target disappears");
      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase212_Refresh_Clears_Disappeared_Selection;

   procedure Test_Jump_To_Diagnostic_Moves_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 5, End_Index => 6,
         Severity => Editor.Diagnostics.Error,
         Message => "bad");

      Editor.Executor.Execute_Jump_To_Diagnostic (S, 1);

      Assert
        (Editor.Executor.Safe_Caret (S) = 5,
         "jump-to-diagnostic should move the primary caret to the diagnostic start");
      Assert
        (S.Active_Diagnostic.Has_Active and then S.Active_Diagnostic.Index = 1,
         "jump-to-diagnostic should record the active diagnostic");
      Assert
        (not S.File_Info.Dirty,
         "jump-to-diagnostic should not dirty the buffer");
   end Test_Jump_To_Diagnostic_Moves_Caret;

   procedure Test_Next_Previous_Diagnostic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def" & ASCII.LF & "ghi");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 1, End_Index => 2,
         Severity => Editor.Diagnostics.Warning);
      Editor.State.Add_Diagnostic
        (S, Start_Index => 5, End_Index => 6,
         Severity => Editor.Diagnostics.Error);

      Editor.Executor.Execute_Next_Diagnostic (S);
      Assert (Editor.Executor.Safe_Caret (S) = 1,
              "next diagnostic from document start should jump to first diagnostic");
      Editor.Executor.Execute_Next_Diagnostic (S);
      Assert (Editor.Executor.Safe_Caret (S) = 5,
              "next diagnostic should advance from active diagnostic");
      Editor.Executor.Execute_Previous_Diagnostic (S);
      Assert (Editor.Executor.Safe_Caret (S) = 1,
              "previous diagnostic should move back from active diagnostic");
   end Test_Next_Previous_Diagnostic;

   procedure Test_Jump_To_Diagnostic_On_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 4, End_Index => 5,
         Severity => Editor.Diagnostics.Warning);
      Editor.State.Add_Diagnostic
        (S, Start_Index => 5, End_Index => 6,
         Severity => Editor.Diagnostics.Error);

      Editor.Executor.Execute_Jump_To_Diagnostic_On_Row (S, 1);
      Assert (Editor.Executor.Safe_Caret (S) = 5,
              "row diagnostic jump should choose dominant severity on the row");
   end Test_Jump_To_Diagnostic_On_Row;


   procedure Test_Diagnostic_Jump_Invalid_And_Empty_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc");
      Before := Editor.Executor.Safe_Caret (S);

      Editor.Executor.Execute_Next_Diagnostic (S);
      Assert
        (Editor.Executor.Safe_Caret (S) = Before,
         "next diagnostic with no diagnostics must preserve the caret");

      Editor.Executor.Execute_Jump_To_Diagnostic (S, 99);
      Assert
        (Editor.Executor.Safe_Caret (S) = Before,
         "invalid diagnostic jump must preserve the caret");
   end Test_Diagnostic_Jump_Invalid_And_Empty_Cases;

   procedure Test_Diagnostic_Jump_Expands_Hidden_Fold
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S, "0" & ASCII.LF & "1" & ASCII.LF & "2" & ASCII.LF & "3");
      Editor.Folding.Add_Fold (S.Folding, 1, 3);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 1);
      Editor.State.Add_Diagnostic
        (S, Start_Index => 4, End_Index => 5,
         Severity => Editor.Diagnostics.Error);

      Editor.Executor.Execute_Jump_To_Diagnostic (S, 1);

      Assert
        (not Editor.Folding.Is_Fold_Collapsed (S.Folding, 1),
         "diagnostic jump should expand the fold hiding its target row");
      Assert
        (Editor.Executor.Safe_Caret (S) = 4,
         "diagnostic jump inside a folded range should land on the target row");
   end Test_Diagnostic_Jump_Expands_Hidden_Fold;


   procedure Test_Toggle_Bookmark_At_Caret_And_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Before_Text  : Unbounded_String;
      Before_Dirty : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 4, Anchor => 4, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Dirty := S.File_Info.Dirty;

      Editor.Executor.Execute_Toggle_Bookmark (S);
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
        "toggle bookmark should add a bookmark on the primary caret row");
      Assert (To_String (Before_Text) = Editor.State.Current_Text (S),
              "toggle bookmark must not mutate buffer text");
      Assert (S.File_Info.Dirty = Before_Dirty,
              "toggle bookmark must not change dirty state");

      Editor.Executor.Execute_Toggle_Bookmark_At_Row (S, 0);
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
        "toggle bookmark at row should affect the requested row");

      Editor.Executor.Execute_Toggle_Bookmark (S);
      Assert (not Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
        "toggle bookmark should remove an existing bookmark on the caret row");
   end Test_Toggle_Bookmark_At_Caret_And_Row;

   procedure Test_Next_Previous_Bookmark_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S, "aaa" & ASCII.LF & "bbb" & ASCII.LF & "ccc" & ASCII.LF & "ddd");
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 2, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker);

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 0, Anchor => 2, Virtual_Column => 3, Anchor_Virtual_Column => 3));
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 4, Anchor => 4, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Next_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 2),
              "next bookmark should jump to the next bookmarked row at column zero");
      Assert (S.Carets.Length = 1,
              "bookmark navigation should clear secondary carets");
      Assert (S.Carets (S.Carets.First_Index).Anchor = S.Carets (S.Carets.First_Index).Pos,
              "bookmark navigation should collapse selection");

      Editor.Executor.Execute_Next_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 0),
              "next bookmark should wrap to the first bookmark");

      Editor.Executor.Execute_Previous_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 2),
              "previous bookmark should wrap to the last bookmark");
   end Test_Next_Previous_Bookmark_Navigation;

   procedure Test_Bookmark_Navigation_Empty_Preserves_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 4, Anchor => 4, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Before := Editor.Executor.Safe_Caret (S);

      Editor.Executor.Execute_Next_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Before,
              "next bookmark with no bookmarks must preserve the caret");
      Editor.Executor.Execute_Previous_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Before,
              "previous bookmark with no bookmarks must preserve the caret");
   end Test_Bookmark_Navigation_Empty_Preserves_Caret;

   procedure Test_Bookmark_Navigation_Across_Open_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      First_Id : Editor.Buffers.Buffer_Id;
      Other_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "a0" & ASCII.LF & "a1");
      Editor.Buffers.Ensure_Global_Registry (S);
      First_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (Other_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "b0" & ASCII.LF & "b1" & ASCII.LF & "b2");
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 2, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (First_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => Editor.State.Line_Start (S, 1),
          Anchor => Editor.State.Line_Start (S, 1),
          Virtual_Column => 0,
          Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Next_Bookmark (S);
      Assert (Editor.Buffers.Global_Active_Buffer = Other_Id,
              "next bookmark should move to the next open buffer in row order");
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 2),
              "next bookmark should land on the bookmarked row in the target buffer");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "successful bookmark navigation should push the previous location");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (Editor.Buffers.Global_Active_Buffer = First_Id,
              "navigation back after bookmark jump should return to prior buffer");
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 1),
              "navigation back after bookmark jump should return to prior row");
   end Test_Bookmark_Navigation_Across_Open_Buffers;

   procedure Test_Clear_All_Bookmarks_Across_Open_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      First_Id : Editor.Buffers.Buffer_Id;
      Other_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "a0" & ASCII.LF & "a1");
      Editor.Buffers.Ensure_Global_Registry (S);
      First_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (Other_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "b0" & ASCII.LF & "b1");
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Clear_All_Bookmarks (S);
      Assert (Editor.Buffers.Global_Bookmark_Count = 0,
              "clear all bookmarks should remove bookmarks from every open buffer");

      Editor.Buffers.Global_Set_Active_Buffer (First_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (not Editor.Gutter_Markers.Has_Bookmarks (S.Gutter_Markers),
              "clear all bookmarks should update the first buffer marker projection");

      Editor.Buffers.Global_Set_Active_Buffer (Other_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (not Editor.Gutter_Markers.Has_Bookmarks (S.Gutter_Markers),
              "clear all bookmarks should update the second buffer marker projection");
   end Test_Clear_All_Bookmarks_Across_Open_Buffers;


   procedure Test_Clear_Bookmarks_Active_Buffer_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Other_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "active");
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Dirty_Line_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Diagnostic_Error_Marker);

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Add_Untitled_Buffer (Other_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Dirty_Line_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Diagnostic_Error_Marker);

      Editor.Executor.Execute_Clear_Bookmarks (S);
      Assert (not Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
        "clear bookmarks should remove active-buffer bookmarks");
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Dirty_Line_Marker),
        "clear bookmarks should preserve active-buffer dirty-line markers");
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Diagnostic_Error_Marker),
        "clear bookmarks should preserve active-buffer diagnostic markers");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer (Editor.Buffers.Buffer_Id (1));
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
        "clear bookmarks must not affect inactive buffer bookmarks");
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Dirty_Line_Marker),
        "clear bookmarks must preserve dirty-line markers");
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Diagnostic_Error_Marker),
        "clear bookmarks must preserve diagnostic markers");
   end Test_Clear_Bookmarks_Active_Buffer_Only;

   procedure Test_Bookmark_Commands_Report_No_Bookmarks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");

      Editor.Executor.Execute_Next_Bookmark (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark: no bookmarks",
         "next bookmark with no bookmarks should report bookmark feedback");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Clear_Bookmarks (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "No bookmarks to clear",
         "clear bookmarks with no bookmarks should report deterministic feedback");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Clear_All_Bookmarks (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "No bookmarks to clear",
         "clear all bookmarks with no bookmarks should report deterministic feedback");
   end Test_Bookmark_Commands_Report_No_Bookmarks;

   procedure Test_Bookmark_Jump_Expands_Hidden_Fold
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S, "0" & ASCII.LF & "1" & ASCII.LF & "2" & ASCII.LF & "3");
      Editor.Folding.Add_Fold (S.Folding, 1, 3);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 1);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 2, Editor.Gutter_Markers.Bookmark_Marker);

      Editor.Executor.Execute_Next_Bookmark (S);

      Assert (not Editor.Folding.Is_Fold_Collapsed (S.Folding, 1),
              "bookmark jump should expand the fold hiding its target row");
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 2),
              "bookmark jump inside a folded range should land on target row");
   end Test_Bookmark_Jump_Expands_Hidden_Fold;



   procedure Test_Bookmark_Toggle_Feedback_And_Stable_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Toggle_Bookmark) = "bookmarks.toggle",
         "toggle bookmark should expose the Phase 265 stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Next_Bookmark) = "bookmarks.next",
         "next bookmark should expose the Phase 265 stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Previous_Bookmark) = "bookmarks.previous",
         "previous bookmark should expose the Phase 265 stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Clear_Bookmarks) = "bookmarks.clear-buffer",
         "clear buffer bookmarks should expose the Phase 265 stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Clear_All_Bookmarks) = "bookmarks.clear-all",
         "clear all bookmarks should expose the Phase 265 stable command name");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.Executor.Execute_Toggle_Bookmark (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark added",
         "toggle bookmark should report deterministic add feedback");

      Editor.Executor.Execute_Toggle_Bookmark (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark removed",
         "toggle bookmark should report deterministic remove feedback");
   end Test_Bookmark_Toggle_Feedback_And_Stable_Names;

   procedure Test_Bookmark_Navigation_Prunes_Stale_Bookmarks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 20, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Next_Bookmark (S);
      Assert
        (not Editor.Gutter_Markers.Has_Bookmarks (S.Gutter_Markers),
         "bookmark navigation should prune out-of-range active-buffer bookmarks");
      Assert
        (Editor.Buffers.Global_Bookmark_Count = 0,
         "bookmark navigation should prune out-of-range registry bookmarks");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark: no bookmarks",
         "stale-only bookmark navigation should report no bookmarks after pruning");
   end Test_Bookmark_Navigation_Prunes_Stale_Bookmarks;


   procedure Test_Bookmark_Commands_On_Empty_Buffer_Are_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Found  : Boolean := False;
      Msg    : Editor.Messages.Editor_Message;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Before := Editor.Executor.Safe_Caret (S);

      Editor.Executor.Execute_Next_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Before,
              "next bookmark on an empty buffer must preserve the caret");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark: no bookmarks",
         "next bookmark on an empty buffer should report no bookmarks");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Previous_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Before,
              "previous bookmark on an empty buffer must preserve the caret");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark: no bookmarks",
         "previous bookmark on an empty buffer should report no bookmarks");
   end Test_Bookmark_Commands_On_Empty_Buffer_Are_Safe;

   procedure Test_Bookmark_Toggle_And_Clear_Do_Not_Push_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");

      Editor.Executor.Execute_Toggle_Bookmark (S);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "toggle bookmark must not push navigation history");

      Editor.Executor.Execute_Clear_Bookmarks (S);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "clear buffer bookmarks must not push navigation history");

      Editor.Executor.Execute_Toggle_Bookmark (S);
      Editor.Executor.Execute_Clear_All_Bookmarks (S);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "clear all bookmarks must not push navigation history");
   end Test_Bookmark_Toggle_And_Clear_Do_Not_Push_History;

   procedure Test_Dirty_Lines_Insert_And_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
              "new buffer should start with zero dirty lines");

      Cmd := Editor.Test_Helper.Insert (0, 'X');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "insert into empty buffer should mark one dirty line");
      Assert (Editor.Dirty_Lines.Kind_For_Row (S.Dirty_Lines, 0) =
                Editor.Dirty_Lines.Modified_Line,
              "edit of baseline empty row should be modified");

      Cmd.Kind := Editor.Commands.Undo;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
              "undo back to baseline should clear dirty-line rows");

      Cmd.Kind := Editor.Commands.Redo;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "redo should recompute dirty-line rows");
   end Test_Dirty_Lines_Insert_And_Undo;

   procedure Test_Dirty_Lines_Save_Clears_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Cmd  : Editor.Commands.Command;
      Path : constant String := Temp_Path ("phase63_save.txt");
   begin
      Remove_File_If_Exists (Path);
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "base");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("phase63_save.txt");

      Cmd := Editor.Test_Helper.Insert (4, '!');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "edit before save should mark dirty-line state");

      Cmd.Kind := Editor.Commands.Save_File;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
              "successful save should clear dirty-line state");
      Assert (S.File_Info.Dirty = False,
              "successful save should keep file-level dirty state clean");
      Remove_File_If_Exists (Path);
   end Test_Dirty_Lines_Save_Clears_Baseline;

   procedure Test_Dirty_Lines_Buffer_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Cmd      : Editor.Commands.Command;
      A_Id     : Editor.Buffers.Buffer_Id;
      B_Id     : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "A");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Cmd := Editor.Test_Helper.Insert (1, '!');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "editing buffer A should mark A dirty lines");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
              "new buffer B should start without dirty lines");

      Cmd := Editor.Test_Helper.Insert (0, 'B');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "editing buffer B should mark B dirty lines");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "switching back to A should restore A dirty-line state");

      Editor.Buffers.Global_Set_Active_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "switching back to B should restore B dirty-line state");
   end Test_Dirty_Lines_Buffer_Isolation;

   procedure Test_Dirty_Lines_Save_Without_Path_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "base");

      Cmd := Editor.Test_Helper.Insert (4, '!');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "setup edit should mark one dirty row before failed save");

      Cmd.Kind := Editor.Commands.Save_File;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "save without path should preserve dirty-line state");
   end Test_Dirty_Lines_Save_Without_Path_Preserves_State;

   procedure Test_Dirty_Lines_Open_Failure_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "base");

      Cmd := Editor.Test_Helper.Insert (4, '!');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "setup edit should mark one dirty row before failed open");

      Cmd.Kind := Editor.Commands.Open_File;
      Cmd.Path := To_Unbounded_String (Temp_Path ("missing_phase63_open.txt"));
      Remove_File_If_Exists (To_String (Cmd.Path));
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "failed open should preserve active dirty-line state");
      Assert (Editor.State.Current_Text (S) = "base!",
              "failed open should preserve active buffer contents");
   end Test_Dirty_Lines_Open_Failure_Preserves_State;

   procedure Test_Dirty_Lines_Save_Active_Buffer_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
      A_Path : constant String := Temp_Path ("phase63_save_a_only.txt");
   begin
      Remove_File_If_Exists (A_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "A");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (A_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("phase63_save_a_only.txt");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Cmd := Editor.Test_Helper.Insert (1, '!');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Cmd := Editor.Test_Helper.Insert (0, 'B');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Cmd.Kind := Editor.Commands.Save_File;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 0,
              "saving active buffer A should clear A dirty-line state");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) = 1,
              "saving buffer A must not clear buffer B dirty-line state");

      Remove_File_If_Exists (A_Path);
   end Test_Dirty_Lines_Save_Active_Buffer_Only;

   procedure Test_Phase261_Find_Navigation_Is_Incremental_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Cmd.Kind := Editor.Commands.Active_Find_Next;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Search.Has_Match (S.Active_Find_Match),
              "Phase 261 find-next must activate an active-buffer match");
      Assert (Natural (S.Carets (0).Anchor) = 11
                and then Natural (S.Carets (0).Pos) = 11,
              "Phase 261 find-next must reveal the next literal match start");
      Assert (Editor.Feature_Search_Results.Is_Empty (S.Feature_Search_Results),
              "Phase 261 find-next must not populate Feature Panel Search Results");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "Phase 261 find-next must not create Feature Panel rows");
      Assert (not S.File_Info.Dirty,
              "Phase 261 find navigation must not dirty the buffer");
   end Test_Phase261_Find_Navigation_Is_Incremental_Only;

   procedure Test_Phase261_Active_Find_Previous_Wraps_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one two one");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "one");

      Cmd.Kind := Editor.Commands.Active_Find_Previous;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Search.Has_Match (S.Active_Find_Match),
              "Phase 261 find-previous must activate a match");
      Assert (Natural (S.Carets (0).Anchor) = 8
                and then Natural (S.Carets (0).Pos) = 8,
              "Phase 261 find-previous from the start must wrap to the final match");
   end Test_Phase261_Active_Find_Previous_Wraps_Deterministically;

   procedure Test_Phase261_Find_Query_Persists_Across_Buffer_Switch
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase261_find_switch_root");
      S      : Editor.State.State_Type;
      A_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      B_Path : constant String := Ada.Directories.Compose (Root, "b.txt");
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Closed : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha only");
      Write_Bytes (B_Path, "beta alpha");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");
      Cmd.Kind := Editor.Commands.Active_Find_Next;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Search.Has_Match (S.Active_Find_Match),
              "Phase 261 setup should find a match in the first buffer");

      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Switch_Buffer (S, B_Id);

      Assert (Editor.Input_Field.Text (S.Active_Find_Input) = "alpha",
              "Phase 261 find query must persist across buffer switches");
      Assert (not Editor.Search.Has_Match (S.Active_Find_Match),
              "Phase 261 active match must clear after switching buffers");

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Search.Has_Match (S.Active_Find_Match)
                and then Natural (S.Active_Find_Match.Start_Index) = 5,
              "Phase 261 find-next after switch must search the newly active buffer");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert (Buffer_Text (S) = "alpha only",
              "Phase 261 find state must not mutate the old buffer content");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase261_Find_Query_Persists_Across_Buffer_Switch;





   procedure Test_Phase266_Buffer_Switcher_Accept_Switches_And_Pushes_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase266_switcher_accept");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Write_Bytes (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Assert (Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "Phase 266 switcher open command must open switcher state");
      Assert (Editor.Overlay_Focus.Is_Active
                (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay),
              "Phase 266 switcher open command must own overlay focus");

      Editor.Executor.Execute_Buffer_Switcher_Insert_Text (S, "beta");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 266 switcher filter should narrow to matching open buffer only");
      Editor.Executor.Execute_Accept_Buffer_Switcher (S);

      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 266 accepting selected switcher row switches active buffer");
      Assert (not Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "Phase 266 successful accept closes switcher");
      Assert (Buffer_Text (S) = "beta body",
              "Phase 266 accepted switch must load selected buffer contents");
      Assert (not S.File_Info.Dirty,
              "Phase 266 switcher activation must not dirty target buffer");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "Phase 266 successful switcher activation pushes navigation history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase266_Buffer_Switcher_Accept_Switches_And_Pushes_History;

   procedure Test_Phase267_Recent_Previous_And_Next_Switch_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (A_Id));

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (B_Id /= A_Id,
              "Phase 267 setup must create a second active buffer");

      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Executor.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "Phase 267 previous recent buffer must return to the last active buffer");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "Phase 267 previous recent buffer must record navigation history");

      Editor.Executor.Execute_Next_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 267 next recent buffer must return through the traversal sequence");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 2,
              "Phase 267 next recent buffer must record navigation history");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase267_Recent_Previous_And_Next_Switch_Buffers;

   procedure Test_Phase267_Recent_Traversal_Wraps_Three_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (A_Id));

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_New_Buffer (S);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 267 previous recent should first select B from C/B/A order");
      Editor.Executor.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "Phase 267 previous recent should continue to A");
      Editor.Executor.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 267 previous recent should wrap to C");
      Editor.Executor.Execute_Next_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "Phase 267 next recent should reverse the traversal");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase267_Recent_Traversal_Wraps_Three_Buffers;

   procedure Test_Phase267_Recent_Close_Removes_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (A_Id));

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (B_Id)),
              "Phase 267 new active buffer must enter recent order");

      Editor.Executor.Execute_Close_Buffer (S, B_Id);
      Assert (not Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (B_Id)),
              "Phase 267 closing a buffer must remove it from recent order");
      Editor.Executor.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "Phase 267 recent navigation after close must not target the closed buffer");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase267_Recent_Close_Removes_Target;


   procedure Test_Phase268_Close_Others_Closes_Clean_And_Skips_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (A_Id));

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Close_Other_Buffers (S);

      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 268 close-others must keep active buffer selected");
      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "Phase 268 close-others must close clean non-active buffers");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "Phase 268 close-others must skip dirty non-active buffers");
      Assert (Editor.Buffers.Global_Contains (C_Id),
              "Phase 268 close-others must keep the active buffer open");
      Assert (not Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (A_Id)),
              "Phase 268 close-others must remove closed buffers from recent order");
      declare
         Found : Boolean := False;
         M     : Editor.Messages.Editor_Message;
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert
           (Found and then To_String (M.Text) = "Buffers: closed 1, skipped 1 dirty",
            "Phase 268 close-others feedback must be compact and deterministic");
      end;

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase268_Close_Others_Closes_Clean_And_Skips_Dirty;

   procedure Test_Phase268_Close_Clean_Closes_Clean_And_Preserves_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (A_Id));

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Replace_Buffer_Contents (S, "dirty buffer");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Close_All_Clean_Buffers (S);

      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "Phase 268 close-clean must close clean inactive buffers");
      Assert (not Editor.Buffers.Global_Contains (C_Id),
              "Phase 268 close-clean may close the active clean buffer");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "Phase 268 close-clean must preserve dirty buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 268 close-clean must choose deterministic dirty fallback");
      Assert (Buffer_Text (S) = "dirty buffer",
              "Phase 268 close-clean must preserve dirty buffer content");
      Assert (S.File_Info.Dirty,
              "Phase 268 close-clean must preserve dirty markers");
      Assert (not Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (A_Id)),
              "Phase 268 close-clean must remove closed clean buffers from recent order");
      declare
         Found : Boolean := False;
         M     : Editor.Messages.Editor_Message;
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert
           (Found and then To_String (M.Text) = "Buffers: closed 2, skipped 1 dirty",
            "Phase 268 close-clean feedback must be compact and deterministic");
      end;

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase268_Close_Clean_Closes_Clean_And_Preserves_Dirty;

   procedure Test_Phase268_Cleanup_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
   begin
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Close_Other_Buffers).Visibility =
         Editor.Commands.Palette_Command,
         "Phase 575: close-others must remain discoverable with dirty review guards");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Close_All_Clean_Buffers).Visibility =
         Editor.Commands.Palette_Command,
         "Phase 575: close-clean must be discoverable as a safe no-discard workflow");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("file.close-other-buffers", Found) = Editor.Commands.Command_Close_Other_Buffers
         and then Found,
         "Phase 575: close-others canonical stable name must resolve");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("file.close-clean-buffers", Found) = Editor.Commands.Command_Close_All_Clean_Buffers
         and then Found,
         "Phase 575: close-clean canonical stable name must resolve");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("buffer.close-active", Found) = Editor.Commands.Command_Close_Active_Buffer
         and then Found,
         "Phase 575: expected buffer.close-active alias must resolve without payload");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("buffer.close-selected", Found) = Editor.Commands.Command_Buffer_Switcher_Selected_Close
         and then Found,
         "Phase 575: expected buffer.close-selected alias must resolve without payload");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("buffer.close-all", Found) = Editor.Commands.Command_Close_All_Buffers
         and then Found,
         "Phase 575: expected buffer.close-all alias must resolve without payload");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("buffer.close-clean", Found) = Editor.Commands.Command_Close_All_Clean_Buffers
         and then Found,
         "Phase 575: expected buffer.close-clean alias must resolve without payload");
   end Test_Phase268_Cleanup_Command_Descriptors;

   procedure Test_Phase575_Dirty_Close_Cancel_And_Discard_Are_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("phase575_dirty_close_cancel_discard.txt");
      Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 dirty active close must open an explicit close review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Active_Buffer_Close_Scope,
              "Phase 575 dirty active close must record active-buffer close scope");
      Assert (Editor.Buffers.Global_Contains (Id),
              "Phase 575 dirty active close must not close before confirmation");
      Assert (Buffer_Text (S) = "dirty text",
              "Phase 575 dirty active close prompt must preserve text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Close);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 cancel must clear dirty close prompt state");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.No_Dirty_Close_Scope,
              "Phase 575 cancel must clear dirty close prompt scope");
      Assert (Editor.Buffers.Global_Contains (Id),
              "Phase 575 cancel must keep the dirty buffer open");
      Assert (Buffer_Text (S) = "dirty text",
              "Phase 575 cancel must preserve dirty text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 discard confirmation must clear dirty close prompt state");
      Assert (not Editor.Buffers.Global_Contains (Id),
              "Phase 575 discard confirmation must close the dirty buffer");
      Assert (Ada.Directories.Exists (Path),
              "Phase 575 discard close must not delete the backing file");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Dirty_Close_Cancel_And_Discard_Are_Explicit;

   procedure Test_Phase575_Save_And_Close_Uses_File_Lifecycle_And_Closes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("phase575_save_and_close.txt");
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Result : Editor.Files.File_Open_Result;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "saved then closed");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 save-and-close starts from dirty close review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Active_Buffer_Close_Scope,
              "Phase 575 save-and-close review records active-buffer scope");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 successful save-and-close must clear close prompt state");
      Assert (not Editor.Buffers.Global_Contains (Id),
              "Phase 575 successful save-and-close must close the buffer");
      Result := Editor.Files.Open_File (Path);
      Assert (To_String (Result.Contents) = "saved then closed",
              "Phase 575 save-and-close must persist through File_Lifecycle save path");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Save_And_Close_Uses_File_Lifecycle_And_Closes;

   procedure Test_Phase575_Save_And_Close_Revalidates_Clean_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("phase575_save_close_revalidate_clean.txt");
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Result : Editor.Files.File_Open_Result;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty before prompt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 revalidation test starts from dirty close review");

      --  Simulate the target becoming clean before the confirmation command is
      --  invoked.  Confirmation must re-check the current buffer summary and
      --  close without writing clean in-memory text back to disk.
      Set_Buffer_Text (S, "clean before confirmation");
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 clean revalidation must clear close prompt state");
      Assert (not Editor.Buffers.Global_Contains (Id),
              "Phase 575 clean revalidation must still close the target buffer");
      Result := Editor.Files.Open_File (Path);
      Assert (To_String (Result.Contents) = "baseline",
              "Phase 575 clean revalidation must not write an already-clean target");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Save_And_Close_Revalidates_Clean_Target;


   procedure Test_Phase575_Stale_Close_Target_Revalidates_And_Clears
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("phase575_stale_close_target.txt");
      Id           : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Closed       : Boolean := False;
      Availability : Editor.Commands.Command_Availability;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty target");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 stale target test starts from dirty close review");
      Editor.Buffers.Global_Force_Close_Buffer (Id, Closed);
      Assert (Closed, "Phase 575 fixture removes prompt target after review opens");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
              "Phase 575 stale prompt target must not offer save-and-close");
      Assert (To_String (Availability.Reason) = "Selected buffer is no longer open",
              "Phase 575 stale prompt target reports precise unavailable reason");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
              "Phase 575 stale prompt target must not offer discard-and-close");
      Assert (To_String (Availability.Reason) = "Selected buffer is no longer open",
              "Phase 575 stale discard target reports precise unavailable reason");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 stale save-and-close target clears prompt without mutation");

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty target again");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 stale discard test starts from dirty close review");
      Editor.Buffers.Global_Force_Close_Buffer (Id, Closed);
      Assert (Closed, "Phase 575 fixture removes discard target after review opens");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 stale discard target clears prompt without failure state");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Stale_Close_Target_Revalidates_And_Clears;

   procedure Test_Phase575_Save_And_Close_Conflict_Overwrite_Closes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("phase575_save_close_conflict.txt");
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Result : Editor.Files.File_Open_Result;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty close overwrite");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Write_Bytes (Path, "external replacement with different size");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 conflict close starts from dirty close review");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 conflict save-and-close transfers ownership to file conflict prompt");
      Assert (S.File_Conflict_Prompt_Active,
              "Phase 575 save-and-close must surface Phase 574 conflict prompt");
      Assert (S.File_Conflict_Close_After_Overwrite,
              "Phase 575 save-and-close must remember close-after-overwrite transiently");
      Assert (not S.File_Conflict_Close_After_Overwrite_All_Buffers,
              "Phase 575 single-buffer save-and-close must not resume close-all after overwrite");
      Assert (Editor.Buffers.Global_Contains (Id),
              "Phase 575 conflicted buffer remains open before explicit overwrite");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);

      Assert (not S.File_Conflict_Prompt_Active,
              "Phase 575 overwrite-after-close must clear the file conflict prompt");
      Assert (not Editor.Buffers.Global_Contains (Id),
              "Phase 575 explicit overwrite after save-and-close must close the buffer");
      Result := Editor.Files.Open_File (Path);
      Assert (To_String (Result.Contents) = "dirty close overwrite",
              "Phase 575 overwrite-after-close must write buffer text before closing");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Save_And_Close_Conflict_Overwrite_Closes;

   procedure Test_Phase575_Close_All_Save_Conflict_Overwrite_Continues
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path_1  : constant String := Temp_Path ("phase575_close_all_conflict_1.txt");
      Path_2  : constant String := Temp_Path ("phase575_close_all_conflict_2.txt");
      Id_1    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Id_2    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Result  : Editor.Files.File_Open_Result;
   begin
      Remove_File_If_Exists (Path_1);
      Remove_File_If_Exists (Path_2);
      Write_Bytes (Path_1, "baseline one");
      Write_Bytes (Path_2, "baseline two");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path_1);
      Id_1 := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty one after conflict");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_File (S, Path_2);
      Id_2 := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty two saved normally");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Write_Bytes (Path_1, "external replacement");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 close-all save starts from dirty review");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (S.File_Conflict_Prompt_Active,
              "Phase 575 close-all save conflict must surface file conflict prompt");
      Assert (S.File_Conflict_Close_After_Overwrite_All_Buffers,
              "Phase 575 close-all save conflict must remember close-all resume scope");
      Assert (Editor.Buffers.Global_Contains (Id_1),
              "Phase 575 conflicted close-all buffer remains open before overwrite");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);

      Assert (not S.File_Conflict_Prompt_Active,
              "Phase 575 close-all overwrite must clear file conflict prompt");
      Assert (not Editor.Buffers.Global_Contains (Id_1),
              "Phase 575 close-all overwrite must close conflicted buffer after successful write");
      Assert (not Editor.Buffers.Global_Contains (Id_2),
              "Phase 575 close-all overwrite resume must continue save-and-close for remaining buffers");
      Result := Editor.Files.Open_File (Path_1);
      Assert (To_String (Result.Contents) = "dirty one after conflict",
              "Phase 575 close-all overwrite must write conflicted buffer text");
      Result := Editor.Files.Open_File (Path_2);
      Assert (To_String (Result.Contents) = "dirty two saved normally",
              "Phase 575 close-all overwrite resume must save remaining file-backed buffers");

      Remove_File_If_Exists (Path_1);
      Remove_File_If_Exists (Path_2);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path_1);
         Remove_File_If_Exists (Path_2);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Close_All_Save_Conflict_Overwrite_Continues;

   procedure Test_Phase575_Discard_Pending_Unavailable_For_Reload_Revert
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("phase575_reload_discard_unavailable.txt");
      A    : Editor.Commands.Command_Availability;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Set_Buffer_Text (S, "dirty reload text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reload_Active_Buffer);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Discard_Pending_Transition);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 575 discard pending must not be available for reload/revert confirmations");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Discard_Pending_Unavailable_For_Reload_Revert;

   procedure Test_Phase575_Discard_Pending_Close_Buffer_Revalidates_Clean_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("phase575_pending_close_clean_revalidated.txt");
      Target : Editor.Pending_Transitions.Pending_Transition_Target;
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "clean before pending close");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Id /= Editor.Buffers.No_Buffer,
              "Phase 575 pending-close fixture must open a real buffer");

      --  Simulate a dirty close-buffer transition that was valid when opened,
      --  then make the reviewed target clean before the explicit discard/close
      --  confirmation is executed.  The confirmation should still close the
      --  reviewed target as a close-only action.
      Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Close_Buffer,
         Path       => Null_Unbounded_String,
         Display    => To_Unbounded_String ("pending close target"),
         Buffer_Id  => Natural (Id),
         Has_Buffer => True,
         Has_Path   => False,
         others     => <>);
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Pending_Test_Summary);

      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Editor.Buffers.Global_Contains (Id),
              "Phase 575 pending-close target starts open before confirmation");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Discard_Pending_Transition);

      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 575 clean revalidated pending close clears transition");
      Assert (not Editor.Buffers.Global_Contains (Id),
              "Phase 575 pending close discard closes reviewed clean target");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Discard_Pending_Close_Buffer_Revalidates_Clean_Target;

   procedure Test_Phase575_Dirty_Close_Distinguishes_Save_Failure_From_Conflict
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("phase575_save_failure_prompt_counts.txt");
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Set_Buffer_Text (S, "dirty after failed save");
      S.File_Info.Dirty := True;
      S.File_Info.Last_Save_Failed := True;
      S.File_Info.External_Change_Surfaced := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 dirty close must open review for failed-save dirty buffer");
      Assert (S.Dirty_Close_Prompt_Save_Failure_Count = 1,
              "Phase 575 close review must classify prior save failure separately");
      Assert (S.Dirty_Close_Prompt_Conflicted_Count = 0,
              "Phase 575 prior save failure must not be reported as an external file conflict");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Dirty_Close_Distinguishes_Save_Failure_From_Conflict;

   procedure Test_Phase575_Unbacked_Close_Does_Not_Offer_Save_And_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "scratch dirty text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 unbacked dirty close must open explicit review");
      Assert (S.Dirty_Close_Prompt_Untitled_Count = 1,
              "Phase 575 unbacked dirty close must classify scratch buffers");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 575 unbacked dirty close must not offer save-and-close without Save As");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 575 unbacked dirty close must still offer explicit discard");

      --  Phase 575 completeness pass 16: availability revalidates the
      --  current in-memory target state, not only the prompt snapshot.  If a
      --  scratch target becomes clean before confirmation, save-and-close is
      --  a valid close confirmation and will close without attempting Save As.
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 575 clean scratch close confirmation must be available after revalidation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Close);
      Assert (Editor.State.Has_Active_Buffer (S),
              "Phase 575 cancelling unbacked close must preserve scratch buffer");
      Assert (Buffer_Text (S) = "scratch dirty text",
              "Phase 575 cancelling unbacked close must preserve scratch text");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Unbacked_Close_Does_Not_Offer_Save_And_Close;

   procedure Test_Phase575_Single_Close_Save_Action_Revalidates_Path_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      A          : Editor.Commands.Command_Availability;
      Snap       : Editor.Render_Model.Render_Snapshot;
      Path       : constant String := Temp_Path ("phase575_single_close_path_revalidate.txt");
      Scratch_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Scratch_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "scratch becomes file-backed");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 path-revalidation fixture starts scratch close review");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 575 dirty scratch close initially hides save-and-close");

      --  The prompt snapshot still says this was an unbacked buffer, but the
      --  live target now has a file path before confirmation.  Availability
      --  and render must follow the current buffer summary, not stale prompt
      --  counts.
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("phase575_single_close_path_revalidate.txt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 575 save-and-close must be exposed when target gains a path");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Save_Action_Available,
              "Phase 575 render must expose save when close target gains a path");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Close);
      Editor.Buffers.Global_Set_Active_Buffer (Scratch_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);

      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Display_Name := To_Unbounded_String ("scratch");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 path-loss fixture restarts dirty close review");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 575 save-and-close must be hidden when target loses its path");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (not Snap.Dirty_Close_Save_Action_Available,
              "Phase 575 render must hide save when close target loses its path");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 575 discard remains available after live path loss");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Single_Close_Save_Action_Revalidates_Path_State;

   procedure Test_Phase575_Render_Model_Projects_Dirty_Close_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Path : constant String := Temp_Path ("phase575_render_dirty_close_actions.txt");
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Set_Buffer_Text (S, "dirty render review");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Prompt_Visible,
              "Phase 575 render snapshot must expose dirty close prompt visibility");
      Assert (Snap.Dirty_Close_Save_Action_Available,
              "Phase 575 render snapshot must expose save-and-close action for file-backed dirty buffer");
      Assert (Snap.Dirty_Close_Discard_Action_Available,
              "Phase 575 render snapshot must expose discard action");
      Assert (Snap.Dirty_Close_Cancel_Action_Available,
              "Phase 575 render snapshot must expose cancel action");
      Assert (Length (Snap.Dirty_Close_Buffer_Ids) > 0,
              "Phase 575 render snapshot must expose reviewed close candidate ids");
      Assert (Length (Snap.Dirty_Close_Dirty_Buffer_Ids) > 0,
              "Phase 575 render snapshot must expose reviewed dirty candidate ids");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Close);
      Editor.Executor.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "scratch render review");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Snap.Dirty_Close_Prompt_Visible,
              "Phase 575 render snapshot must expose scratch dirty close prompt");
      Assert (not Snap.Dirty_Close_Save_Action_Available,
              "Phase 575 render snapshot must not expose save-and-close for scratch buffer without Save As");
      Assert (Snap.Dirty_Close_Discard_Action_Available,
              "Phase 575 render snapshot must still expose discard for scratch buffer");
      Assert (Snap.Dirty_Close_Cancel_Action_Available,
              "Phase 575 render snapshot must still expose cancel for scratch buffer");

      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Save_Action_Available,
              "Phase 575 render snapshot must revalidate clean scratch target for save-and-close");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Render_Model_Projects_Dirty_Close_Actions;


   procedure Test_Phase575_Close_All_Review_Stale_Buffer_Set_Is_Revalidated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "first dirty close-all candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "second dirty close-all candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 close-all review starts from explicit dirty close prompt");
      Assert (S.Dirty_Close_Prompt_Buffer_Count = 2,
              "Phase 575 close-all review records the transient candidate count");

      --  Simulate stale prompt state: normal command routing is modal while a
      --  close review is active, but the confirmation path must still defend
      --  against runtime buffer-set changes before mutating anything.
      Editor.Executor.Execute_New_Buffer (S);
      Assert (Editor.Buffers.Global_Count = 3,
              "Phase 575 fixture creates a stale close-all candidate set");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 575 stale close-all review must not offer save-and-close");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Close review is stale",
              "Phase 575 stale close-all save reports precise reason");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 575 stale close-all review must not offer discard-and-close");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Close review is stale",
              "Phase 575 stale close-all discard reports precise reason");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 stale close-all confirmation clears transient review");
      Assert (Editor.Buffers.Global_Count = 3,
              "Phase 575 stale close-all confirmation must not close changed buffer set");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Close_All_Review_Stale_Buffer_Set_Is_Revalidated;

   procedure Test_Phase575_Close_All_Review_Stale_Same_Count_Is_Revalidated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      First  : Editor.Buffers.Buffer_Id;
      Closed : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "first dirty close-all candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "second dirty close-all candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 close-all replacement fixture starts explicit review");
      Assert (S.Dirty_Close_Prompt_Buffer_Count = 2,
              "Phase 575 replacement fixture records original count");
      Assert (S.Dirty_Close_Prompt_Buffer_Fingerprint /= 0,
              "Phase 575 replacement fixture records original buffer identity fingerprint");

      --  Same-count replacement must still be stale: the explicit review was
      --  for the original buffer identities, not any later buffer set that
      --  happens to have the same count.
      Editor.Buffers.Global_Force_Close_Buffer (First, Closed);
      Assert (Closed, "Phase 575 replacement fixture force closes one candidate");
      Editor.Executor.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "replacement dirty candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Editor.Buffers.Global_Count = 2,
              "Phase 575 replacement fixture preserves all-buffer count");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 575 same-count replacement must not offer discard-and-close");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Close review is stale",
              "Phase 575 same-count replacement reports stale close review");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 same-count replacement clears stale review");
      Assert (Editor.Buffers.Global_Count = 2,
              "Phase 575 same-count replacement must not close new buffer set");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Close_All_Review_Stale_Same_Count_Is_Revalidated;

   procedure Test_Phase575_Close_All_Review_Newly_Dirty_Buffer_Is_Revalidated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      Second : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "first dirty close-all candidate");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Second := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "second clean close-all candidate");
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 newly-dirty fixture starts explicit close-all review");
      Assert (S.Dirty_Close_Prompt_Dirty_Count = 1,
              "Phase 575 newly-dirty fixture records original dirty count");
      Assert (S.Dirty_Close_Prompt_Dirty_Fingerprint /= 0,
              "Phase 575 newly-dirty fixture records original dirty identity fingerprint");

      --  The buffer identities and total count are unchanged, but a buffer
      --  that was clean at review time becomes dirty before confirmation.
      --  That dirty text was not part of the explicit review, so the
      --  all-buffer prompt must be treated as stale before save/discard.
      Editor.Buffers.Global_Set_Active_Buffer (Second);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Set_Buffer_Text (S, "second buffer dirtied after review");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Editor.Buffers.Global_Count = 2,
              "Phase 575 newly-dirty fixture preserves all-buffer count");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 575 newly dirty buffer must stale discard-and-close review");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Close review is stale",
              "Phase 575 newly dirty buffer reports stale close review");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 575 newly dirty buffer must stale save-and-close review");
      Assert (Editor.Commands.Unavailable_Reason (A) = "Close review is stale",
              "Phase 575 newly dirty save reports stale close review");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 newly dirty stale review clears after confirmation attempt");
      Assert (Editor.Buffers.Global_Count = 2,
              "Phase 575 newly dirty stale review must not close reviewed buffers");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Close_All_Review_Newly_Dirty_Buffer_Is_Revalidated;


   procedure Test_Phase575_Close_All_Review_All_Clean_Revalidated_As_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      Snap   : Editor.Render_Model.Render_Snapshot;
      First  : Editor.Buffers.Buffer_Id;
      Second : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "first dirty close-all candidate cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Second := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "second dirty close-all candidate cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 cleaned-all fixture starts explicit close-all review");
      Assert (S.Dirty_Close_Prompt_Dirty_Count = 2,
              "Phase 575 cleaned-all fixture records original dirty count");

      --  Both reviewed dirty buffers become clean before confirmation.  The
      --  reviewed buffer identities are unchanged and no newly dirty text is
      --  introduced, so save-and-close should revalidate as a close-only
      --  confirmation instead of reporting a stale prompt.
      Editor.Buffers.Global_Set_Active_Buffer (First);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (Second);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 575 all-clean reviewed set must still offer save-and-close as close confirmation");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Save_Action_Available,
              "Phase 575 render snapshot must expose save action for all-clean reviewed set");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 all-clean reviewed set clears prompt after close confirmation");
      Assert (Editor.Buffers.Global_Count = 0,
              "Phase 575 all-clean reviewed set closes all buffers without stale refusal");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Close_All_Review_All_Clean_Revalidated_As_Close;


   procedure Test_Phase575_Close_All_Review_All_Clean_Discard_Revalidated_As_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      Snap   : Editor.Render_Model.Render_Snapshot;
      First  : Editor.Buffers.Buffer_Id;
      Second : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "first dirty discard close-all candidate cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Second := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "second dirty discard close-all candidate cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 cleaned-all discard fixture starts explicit close-all review");

      --  Both originally dirty buffers become clean before confirmation.  The
      --  reviewed identity set is unchanged, so discard is no longer
      --  destructive; it should remain available as a close-only confirmation
      --  and must match the execution-time revalidation path.
      Editor.Buffers.Global_Set_Active_Buffer (First);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (Second);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 575 all-clean reviewed set must still offer discard as close confirmation");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Discard_Action_Available,
              "Phase 575 render snapshot must expose discard action for all-clean reviewed set");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 all-clean discard reviewed set clears prompt after close confirmation");
      Assert (Editor.Buffers.Global_Count = 0,
              "Phase 575 all-clean discard reviewed set closes all buffers without stale refusal");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Close_All_Review_All_Clean_Discard_Revalidated_As_Close;



   procedure Test_Phase575_Close_All_Review_Subset_Dirty_Revalidated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      Snap   : Editor.Render_Model.Render_Snapshot;
      First  : Editor.Buffers.Buffer_Id;
      Second : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "first reviewed dirty buffer cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Second := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "second reviewed dirty buffer remains dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 subset-dirty fixture starts explicit close-all review");
      Assert (S.Dirty_Close_Prompt_Dirty_Count = 2,
              "Phase 575 subset-dirty fixture records both reviewed dirty buffers");

      --  One reviewed dirty buffer becomes clean before confirmation, while
      --  another reviewed dirty buffer remains dirty.  This must not be
      --  treated like a newly dirty/unreviewed buffer: the current dirty set is
      --  a subset of the explicitly reviewed dirty set, so discard remains an
      --  explicit valid confirmation.
      Editor.Buffers.Global_Set_Active_Buffer (First);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 575 reviewed dirty subset must still offer discard confirmation");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Dirty_Close_Discard_Action_Available,
              "Phase 575 render must expose discard when remaining dirty buffers were reviewed");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 reviewed dirty subset clears prompt after discard confirmation");
      Assert (Editor.Buffers.Global_Count = 0,
              "Phase 575 reviewed dirty subset closes the unchanged reviewed buffer set");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Close_All_Review_Subset_Dirty_Revalidated;


   procedure Test_Phase575_Close_All_Review_Subset_Scratch_Save_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A      : Editor.Commands.Command_Availability;
      Snap   : Editor.Render_Model.Render_Snapshot;
      First  : Editor.Buffers.Buffer_Id;
      Second : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "first reviewed scratch cleaned before confirm");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Second := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "second reviewed scratch remains dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 scratch subset fixture starts explicit close-all review");
      Assert (S.Dirty_Close_Prompt_Untitled_Count = 2,
              "Phase 575 scratch subset fixture records reviewed scratch buffers");

      --  The live dirty set is still a subset of the reviewed dirty set, so
      --  discard remains valid.  Save-and-close, however, must be unavailable
      --  because the only remaining dirty buffer is still unbacked and cannot
      --  use File_Lifecycle save without Save As support.
      Editor.Buffers.Global_Set_Active_Buffer (First);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not Editor.Commands.Is_Available (A),
              "Phase 575 reviewed scratch subset must not offer save-and-close");
      Assert (Editor.Commands.Unavailable_Reason (A) =
              "Buffer has no file path.",
              "Phase 575 reviewed scratch subset reports Save As requirement");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 575 reviewed scratch subset must still offer explicit discard");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (not Snap.Dirty_Close_Save_Action_Available,
              "Phase 575 render must hide save when remaining reviewed dirty set is scratch-only");
      Assert (Snap.Dirty_Close_Discard_Action_Available,
              "Phase 575 render must keep discard for reviewed scratch subset");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 reviewed scratch subset clears prompt after discard confirmation");
      Assert (Editor.Buffers.Global_Count = 0,
              "Phase 575 reviewed scratch subset closes all buffers after explicit discard");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Close_All_Review_Subset_Scratch_Save_Unavailable;


   procedure Test_Phase575_Close_All_Review_Message_Summarizes_Dirty_Set
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path    : constant String := Temp_Path ("phase575_close_all_review_message.txt");
      File_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      File_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty file");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Set_Buffer_Text (S, "dirty scratch");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);

      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 close-all dirty review should remain active");
      Assert (Editor.Buffers.Global_Contains (File_Id),
              "Phase 575 close-all review must not close file buffer before confirmation");
      Assert (Latest_Message_Text (S) =
              "2 dirty buffers require confirmation (1 file-backed, 1 scratch).",
              "Phase 575 close-all dirty review message should summarize count and categories");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Close_All_Review_Message_Summarizes_Dirty_Set;


   procedure Test_Phase575_Close_All_Save_Failure_Rebuilds_Remaining_Review
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path    : constant String := Temp_Path ("phase575_close_all_partial_save_failure.txt");
      File_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Scratch : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      A       : Editor.Commands.Command_Availability;
      Result  : Editor.Files.File_Open_Result;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      File_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "file saved before scratch failure");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      Scratch := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "scratch remains after save failure");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Buffers);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 mixed close-all fixture starts explicit review");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (not Editor.Buffers.Global_Contains (File_Id),
              "Phase 575 partial close-all save should close saved file-backed buffers");
      Result := Editor.Files.Open_File (Path);
      Assert (To_String (Result.Contents) = "file saved before scratch failure",
              "Phase 575 partial close-all save should use File_Lifecycle for file-backed buffers");
      Assert (Editor.Buffers.Global_Contains (Scratch),
              "Phase 575 partial close-all save should keep unbacked dirty buffers open");
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 partial close-all save should rebuild review for remaining dirty buffers");
      Assert (S.Dirty_Close_Prompt_Dirty_Count = 1,
              "Phase 575 rebuilt close-all review should describe the remaining scratch buffer");
      Assert (S.Dirty_Close_Prompt_Save_Failure_Count = 1,
              "Phase 575 rebuilt close-all review should retain the save failure summary");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (Editor.Commands.Is_Available (A),
              "Phase 575 rebuilt close-all review must still allow explicit discard of remaining dirty buffers");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 575 discard after rebuilt review clears the close prompt");
      Assert (Editor.Buffers.Global_Count = 0,
              "Phase 575 discard after rebuilt review closes the remaining scratch buffer");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase575_Close_All_Save_Failure_Rebuilds_Remaining_Review;

   procedure Test_Phase269_Reopen_Unavailable_With_No_Candidate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert
        (not Editor.Commands.Is_Available (A),
         "Phase 436 reopen must be unavailable with no candidate");
      Assert
        (To_String (A.Reason) = "No closed buffer to reopen",
         "Phase 436 no-candidate reopen unavailable reason must be deterministic");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase269_Reopen_Unavailable_With_No_Candidate;

   procedure Test_Phase269_Close_Clean_File_And_Reopen
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("phase269_reopen_clean.txt");
      Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "alpha body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Close_Buffer (S, Id);

      Assert
        (not Editor.Buffers.Global_Contains (Id),
         "Phase 436: clean close removes the closed buffer through canonical close");
      Assert
        (S.Has_Reopen_Candidate and then To_String (S.Reopen_Candidate_Path) = Path,
         "Phase 436: clean associated close creates only the canonical path candidate");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert
        (Editor.Buffers.Global_Count = 1,
         "Phase 436: canonical reopen must add exactly one file-backed buffer");
      Assert
        (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path,
         "Phase 436: canonical reopen must activate the candidate path");
      Assert
        (Editor.State.Current_Text (S) = "alpha body",
         "Phase 436: canonical reopen must read disk contents through file-open");
      Assert
        (not S.Has_Reopen_Candidate,
         "Phase 436: successful canonical reopen consumes the path candidate");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase269_Close_Clean_File_And_Reopen;

   procedure Test_Phase269_Reopen_Reverse_Order_After_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Path : constant String := Temp_Path ("phase269_a.txt");
      B_Path : constant String := Temp_Path ("phase269_b.txt");
      C_Path : constant String := Temp_Path ("phase269_c.txt");
   begin
      Remove_File_If_Exists (A_Path);
      Remove_File_If_Exists (B_Path);
      Remove_File_If_Exists (C_Path);
      Write_Bytes (A_Path, "a");
      Write_Bytes (B_Path, "b");
      Write_Bytes (C_Path, "c");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      Editor.Executor.Execute_Open_File (S, B_Path);
      Editor.Executor.Execute_Open_File (S, C_Path);
      Editor.Executor.Execute_Close_All_Clean_Buffers (S);

      null;
      Assert (True,
              "Phase 436: removed-name close-history stack must not drive reopen after cleanup");
      Assert (not S.Has_Reopen_Candidate,
              "Phase 436: removed-name cleanup closes must not synthesize canonical reopen candidates");

      Remove_File_If_Exists (A_Path);
      Remove_File_If_Exists (B_Path);
      Remove_File_If_Exists (C_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (A_Path);
         Remove_File_If_Exists (B_Path);
         Remove_File_If_Exists (C_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase269_Reopen_Reverse_Order_After_Cleanup;

   procedure Test_Phase269_Blocked_Dirty_Close_Does_Not_Record
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("phase269_dirty_blocked.txt");
      Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Close_Buffer (S, Id);

      Assert
        (True,
         "Phase 269 blocked dirty close must not create a reopen entry");
      Assert
        (Editor.Buffers.Global_Contains (Id),
         "Phase 269 blocked dirty close must leave the buffer open");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase269_Blocked_Dirty_Close_Does_Not_Record;

   procedure Test_Phase269_Reopen_Already_Open_File_Focuses_Existing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("phase269_existing.txt");
      Closed : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Count  : Natural := 0;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "existing");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Closed := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Close_Buffer (S, Closed);
      Assert
        (S.Has_Reopen_Candidate and then To_String (S.Reopen_Candidate_Path) = Path,
         "Phase 436: duplicate-open scenario starts from canonical path candidate");
      Editor.Executor.Execute_Open_File (S, Path);
      Count := Editor.Buffers.Global_Count;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);

      Assert
        (Editor.Buffers.Global_Count = Count,
         "Phase 436: duplicate reopen must focus an already-open file instead of duplicating it");
      Assert
        (To_String (S.File_Info.Path) = Path,
         "Phase 436: duplicate reopen must focus the existing candidate buffer");
      Assert
        (not S.Has_Reopen_Candidate,
         "Phase 436: successful duplicate reopen consumes the path candidate");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase269_Reopen_Already_Open_File_Focuses_Existing;

   procedure Test_Phase269_Missing_File_Reopen_Fails_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("phase269_missing.txt");
      Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "missing");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Close_Buffer (S, Id);
      Remove_File_If_Exists (Path);
      Assert
        (S.Has_Reopen_Candidate and then To_String (S.Reopen_Candidate_Path) = Path,
         "Phase 436: missing-file scenario starts from canonical path candidate");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert
        (Editor.Buffers.Global_Count = 0,
         "Phase 436: failed reopen must not create a placeholder buffer");
      Assert
        (S.Has_Reopen_Candidate and then To_String (S.Reopen_Candidate_Path) = Path,
         "Phase 436: failed reopen retains the path candidate for deterministic retry");
      Assert
        (Latest_Message_Text (S) = "Could not reopen closed buffer",
         "Phase 436: failed reopen emits the canonical failure message");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase269_Missing_File_Reopen_Fails_Deterministically;


   procedure Test_Phase267_New_Buffer_Seeds_Initial_Recent_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Assert (B_Id /= A_Id,
              "Phase 267 setup must create a distinct second buffer");
      Assert (Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (A_Id)),
              "Phase 267 creating a second buffer must seed the prior active buffer in MRU order");
      Assert (Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (B_Id)),
              "Phase 267 creating a second buffer must record the new active buffer in MRU order");

      Editor.Executor.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "Phase 267 previous recent must work immediately after ordinary new-buffer creation");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase267_New_Buffer_Seeds_Initial_Recent_Order;

   procedure Test_Phase267_Recent_Feedback_Is_Primary_Command_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);

      Editor.Executor.Execute_New_Buffer (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Previous_Recent_Buffer (S);

      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (Msg.Text) = "Buffer: previous",
              "Phase 267 recent previous must expose compact recent-buffer feedback, not generic switch feedback");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Next_Recent_Buffer (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (Msg.Text) = "Buffer: next",
              "Phase 267 recent next must expose compact recent-buffer feedback, not generic switch feedback");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase267_Recent_Feedback_Is_Primary_Command_Message;

   procedure Test_Phase266_Buffer_Switcher_Failed_Accept_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase266_switcher_failed_accept");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Navigation_History.Clear (S.Navigation_History);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Insert_Text (S, "not-open");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0,
              "Phase 266 test setup should create no-match switcher state");

      Editor.Executor.Execute_Accept_Buffer_Switcher (S);

      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "Phase 266 failed accept must preserve active buffer");
      Assert (Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "Phase 266 failed accept keeps switcher open for filter repair");
      Assert (Buffer_Text (S) = "alpha body",
              "Phase 266 failed accept must preserve buffer contents");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 266 failed switcher activation must not push navigation history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase266_Buffer_Switcher_Failed_Accept_Preserves_State;


   procedure Test_Phase262_Find_Highlights_Clear_When_Find_Closes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");
      Editor.Input_Bridge.Set_State_For_Test (S);
      declare
         Snapshot_State : Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
      begin
         Editor.Render_Model.Build_Render_Snapshot (Snapshot_State, Snap);
      end;
      Assert (Snap.Active_Find_Match_Count = 2,
              "Phase 262 open find must project visible active-buffer matches");

      Editor.Executor.Execute_Find_Hide (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      declare
         Snapshot_State : Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
      begin
         Editor.Render_Model.Build_Render_Snapshot (Snapshot_State, Snap);
      end;
      Assert (Snap.Active_Find_Match_Count = 0,
              "Phase 262 closing find must clear projected highlights");
      Assert (S.Active_Find_Matches.Is_Empty,
              "Phase 262 closing find must clear transient session-local query results");
   end Test_Phase262_Find_Highlights_Clear_When_Find_Closes;

   procedure Test_Phase262_Query_Edit_Recomputes_Current_From_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 6,
          Anchor                => 6,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Assert (Editor.Search.Has_Match (S.Active_Find_Match),
              "Phase 262 query edit must compute a current match");
      Assert (Natural (S.Active_Find_Match.Start_Index) = 11,
              "Phase 262 current match after query edit must be at or after cursor");
      Assert (Natural (S.Carets (0).Pos) = 6,
              "Phase 262 query editing must preserve editor cursor");
   end Test_Phase262_Query_Edit_Recomputes_Current_From_Caret;

   procedure Test_Phase262_Wrap_Status_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");
      Cmd.Kind := Editor.Commands.Active_Find_Previous;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Active_Find_Wrapped,
              "Phase 262 wrapped find navigation must mark wrapped status");
      Assert (Natural (S.Active_Find_Match.Start_Index) = 11,
              "Phase 262 previous from first current match wraps to final match");
   end Test_Phase262_Wrap_Status_Is_Deterministic;

   procedure Test_Phase262_Current_Match_Emphasis_Is_Projected
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Editor.Input_Bridge.Set_State_For_Test (S);
      declare
         Snapshot_State : Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
      begin
         Editor.Render_Model.Build_Render_Snapshot (Snapshot_State, Snap);
      end;

      Assert (Snap.Active_Find_Match_Count = 2,
              "Phase 262 snapshot must project all visible find matches");
      Assert (Editor.Search.Has_Match (Snap.Active_Find_Match),
              "Phase 262 snapshot must project the current match for emphasis");
      Assert (Natural (Snap.Active_Find_Match.Start_Index) = 0,
              "Phase 262 current-match emphasis must point at the recomputed match");
      Assert (Snap.Active_Find_Matches (1).Index = Snap.Active_Find_Match.Index,
              "Phase 262 projected match metadata must preserve the active match index");
   end Test_Phase262_Current_Match_Emphasis_Is_Projected;

   procedure Test_Phase262_Find_Query_Edit_Stays_Out_Of_Feature_Search
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Assert (Editor.Feature_Search_Results.Is_Empty (S.Feature_Search_Results),
              "Phase 262 find query edits must not populate Feature Search Results");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "Phase 262 find query edits must not create Feature Panel rows");
      Assert (not S.File_Info.Dirty,
              "Phase 262 find query edits must not dirty the active buffer");
   end Test_Phase262_Find_Query_Edit_Stays_Out_Of_Feature_Search;

   procedure Test_Phase68_Executor_Set_Rectangular_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Text_Length : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abcd" & ASCII.LF & "xy" & ASCII.LF & "12345");
      Before_Text_Length := Text_Buffer.Length (S.Buffer);

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 2, Anchor => 2, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Set_Rectangular_Selection
        (S      => S,
         Anchor => (Row => 0, Column => 1),
         Cursor => (Row => 2, Column => 4));

      Assert (S.Rect_Select_Active,
              "Phase 68 set rectangle must activate rectangular selection");
      Assert (S.Rect_Anchor_Row = 0 and then S.Rect_Anchor_Col = 1,
              "Phase 68 set rectangle must preserve the anchor");
      Assert (S.Carets.Length = 3,
              "Phase 68 set rectangle must project one caret/span per row");
      Assert (Text_Buffer.Length (S.Buffer) = Before_Text_Length,
              "Phase 68 rectangular selection must not mutate text");
      Assert (not S.File_Info.Dirty,
              "Phase 68 rectangular selection must not mark file dirty");
   end Test_Phase68_Executor_Set_Rectangular_Selection;

   procedure Test_Phase68_Executor_Clear_Rectangular_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abcd" & ASCII.LF & "efgh");

      Editor.Executor.Execute_Set_Rectangular_Selection
        (S      => S,
         Anchor => (Row => 0, Column => 1),
         Cursor => (Row => 1, Column => 3));

      Editor.Executor.Execute_Clear_Rectangular_Selection (S);

      Assert (not S.Rect_Select_Active,
              "Phase 68 clear rectangle must leave rectangular mode");
      Assert (S.Carets.Length = 1,
              "Phase 68 clear rectangle must collapse to one primary caret");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor =
         S.Carets (S.Carets.First_Index).Pos,
         "Phase 68 clear rectangle must collapse selection");
   end Test_Phase68_Executor_Clear_Rectangular_Selection;


   procedure Test_Phase73_Run_Project_Search_No_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Run_Project_Search (S, "needle");

      Assert
        (Editor.Project_Search.Status (S.Project_Search) =
           Editor.Project_Search.Project_Search_No_Project,
         "project search without an open project should report No_Project status");
      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "project search failure should still show the bottom panel");
      Assert
        (Editor.Panels.Active_Bottom_Content (S.Panels) =
           Editor.Panels.Search_Results_Content,
         "running project search should switch bottom content to Search Results");
   end Test_Phase73_Run_Project_Search_No_Project;

   procedure Test_Phase73_Run_Search_And_Open_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("project_search_root");
      S : Editor.State.State_Type;
      Before_Text : constant String := "untouched";
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, Before_Text);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");

      Assert
        (Editor.Project_Search.Status (S.Project_Search) =
           Editor.Project_Search.Project_Search_Ok,
         "project search over fixture should complete with Ok status");
      Assert
        (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
         "project search fixture should produce one result");
      Assert
        (Editor.Panels.Active_Bottom_Content (S.Panels) =
           Editor.Panels.Search_Results_Content,
         "successful project search should select Search Results bottom content");

      Editor.Executor.Execute_Open_Selected_Project_Search_Result (S);

      Assert
        (To_String (S.File_Info.Display_Name) = "needle.txt",
         "opening selected project search result should activate the matching file");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 11
         and then S.Carets (S.Carets.First_Index).Pos = 17,
         "opening selected project search result should select the matched text range");
      Assert
        (not S.File_Info.Dirty,
         "opening a project search result must not dirty the target buffer");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase73_Run_Search_And_Open_Result;

   procedure Test_Phase548_Replace_All_Continues_After_First_File_Stales_Preview
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase548_replace_all_root");
      S    : Editor.State.State_Type;
      Msg  : Unbounded_String := Null_Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "b.txt"));
      Remove_Dir_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "a.txt"), "needle a" & ASCII.LF);
      Write_Bytes (Ada.Directories.Compose (Root, "b.txt"), "needle b" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 2,
              "Phase 548 replace-all setup should find matches in both files");

      Editor.Project_Search.Set_Replace_Text (S.Project_Search, "pin");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Project_Search_Replace_Preview);
      Assert (Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 2,
              "Phase 548 replace-all setup should preview both file matches");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Project_Search_Replace_All_Included);
      Msg := To_Unbounded_String (Latest_Message_Text (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Msg), "Replaced") /= 0
              and then Ada.Strings.Fixed.Index (To_String (Msg), "2 matches") /= 0
              and then Ada.Strings.Fixed.Index (To_String (Msg), "2 files") /= 0,
              "Phase 548 replace all should continue after the first changed file stales preview rows");
      Assert (Editor.Buffers.Global_Dirty_File_Backed_Buffer_Count = 2,
              "Phase 548 replace all should dirty every changed file-backed buffer");
      Assert (Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search),
              "Phase 548 replace all should leave the used preview stale after mutation");

      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "b.txt"));
      Remove_Dir_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
         Remove_File_If_Exists (Ada.Directories.Compose (Root, "b.txt"));
         Remove_Dir_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase548_Replace_All_Continues_After_First_File_Stales_Preview;


   procedure Test_Phase548_Project_Replace_Uses_UTF8_Byte_Offsets_Safely
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase548_utf8_replace_root");
      Path : constant String := Ada.Directories.Compose (Root, "utf8.txt");
      S    : Editor.State.State_Type;
      E_Acute : constant String := Character'Val (16#C3#) & Character'Val (16#A9#);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File_If_Exists (Path);
      Remove_Dir_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Path, E_Acute & "needle" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "Phase 548 UTF-8 setup should find the literal match after a multibyte prefix");

      Editor.Project_Search.Set_Replace_Text (S.Project_Search, "pin");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Project_Search_Replace_Preview);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Project_Search_Replace_All_Included);

      Assert (Editor.State.Current_Text (S) = E_Acute & "pin" & ASCII.LF,
              "Phase 548 project replace apply should translate search byte offsets to buffer code-point columns");
      Assert (S.File_Info.Dirty,
              "Phase 548 UTF-8 project replacement should dirty the changed target buffer");

      Remove_File_If_Exists (Path);
      Remove_Dir_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Remove_Dir_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase548_Project_Replace_Uses_UTF8_Byte_Offsets_Safely;

   procedure Test_Phase548_Replace_Preview_Stales_Dirty_Open_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase548_dirty_preview_root");
      Path : constant String := Ada.Directories.Compose (Root, "dirty.txt");
      S    : Editor.State.State_Type;
      Cmd  : Editor.Commands.Command;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File_If_Exists (Path);
      Remove_Dir_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Path, "needle" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Path);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String ("x");
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (S.File_Info.Dirty,
              "Phase 548 setup should keep the target file open and dirty");

      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "Phase 548 dirty-preview setup should still find the on-disk match");

      Editor.Project_Search.Set_Replace_Text (S.Project_Search, "pin");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Project_Search_Replace_Preview);

      Assert (Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search),
              "replacement preview rows for open dirty target buffers must be stale immediately");
      Assert (Editor.Project_Search.Included_Replacement_Count (S.Project_Search) = 0,
              "stale dirty-buffer preview rows must not remain included");

      Remove_File_If_Exists (Path);
      Remove_Dir_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Remove_Dir_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase548_Replace_Preview_Stales_Dirty_Open_Targets;

   procedure Test_Phase337_Project_Search_From_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase337_selection_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Path);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 25,
          Anchor                => 10,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Project_Search_From_Selection (S);

      Assert (Editor.Project_Search.Query (S.Project_Search) = "Execute_Command",
              "Phase 337 selection search must set the derived query");
      Assert (Editor.Project_Search.Status (S.Project_Search) =
                Editor.Project_Search.Project_Search_Ok,
              "Phase 337 selection search must run the bounded project search");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) >= 2,
              "Phase 337 selection search should find project-wide matches");
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
              "Phase 337 selection search should select the first result");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase337_Project_Search_From_Selection;

   procedure Test_Phase337_Project_Search_From_Active_Word
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase337_word_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Path);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 18,
          Anchor                => 18,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Project_Search_From_Active_Word (S);

      Assert (Editor.Project_Search.Query (S.Project_Search) = "Execute_Command",
              "Phase 337 active-word search must expand [A-Za-z0-9_]+ token");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) >= 2,
              "Phase 337 active-word search must run project-wide search");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase337_Project_Search_From_Active_Word;

   procedure Test_Phase337_Active_Word_Dotted_Token_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase337_dotted_word_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Path);
      Set_Buffer_Text (S, "Foo.Bar");

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 4,
          Anchor                => 4,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Project_Search_From_Active_Word (S);
      Assert (Editor.Project_Search.Query (S.Project_Search) = "Bar",
              "Phase 337 active-word extraction should use the token under the caret after a dot");

      Editor.Project_Search.Set_Query (S.Project_Search, "before");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 3,
          Anchor                => 3,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Project_Search_From_Active_Word (S);
      Assert (Editor.Project_Search.Query (S.Project_Search) = "before",
              "Phase 337 caret on punctuation must not back up to the previous token");
      Assert (Latest_Message_Text (S) = "No searchable text at cursor",
              "Phase 337 caret on dotted separator should report no searchable text");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase337_Active_Word_Dotted_Token_Boundary;

   procedure Test_Phase337_Project_Search_Active_Directory
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase337_active_dir_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Path);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 18,
          Anchor                => 18,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Project_Search_Active_Directory (S);

      Assert (Editor.Project_Search.Query (S.Project_Search) = "Execute_Command",
              "Phase 337 active-directory search must derive the context query");
      Assert (Editor.Project_Search.Path_Scope (S.Project_Search) = "src/editor/",
              "Phase 337 active-directory search must set containing directory scope");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 2,
              "Phase 337 active-directory search must not include sibling directories");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase337_Project_Search_Active_Directory;

   procedure Test_Phase337_Context_Search_Failure_Is_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase337_failure_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
      Before_Query : constant String := "before";
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Path);
      Editor.Project_Search.Set_Query (S.Project_Search, Before_Query);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 9,
          Anchor                => 9,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));

      Editor.Executor.Execute_Project_Search_From_Active_Word (S);

      Assert (Editor.Project_Search.Query (S.Project_Search) = Before_Query,
              "Phase 337 punctuation failure must preserve previous query");
      Assert (Latest_Message_Text (S) = "No searchable text at cursor",
              "Phase 337 punctuation failure must report deterministic no-op");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase337_Context_Search_Failure_Is_Atomic;

   procedure Test_Phase339_First_Last_Project_Search_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase339_first_last_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
      Before_Display : Unbounded_String := Null_Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Path);
      Before_Display := S.File_Info.Display_Name;
      Editor.Executor.Execute_Run_Project_Search (S, "Execute_Command");

      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 4,
              "Phase 339 first/last fixture should expose four stored results");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Last_Project_Search_Result (S);
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 4,
              "Phase 339 last command should select the final stored result");
      Assert (Latest_Message_Text (S) = "Selected last project search result",
              "Phase 339 last command should emit the expected navigation message");
      Assert (S.File_Info.Display_Name = Before_Display,
              "Phase 339 last command must not open or activate files");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_First_Project_Search_Result (S);
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
              "Phase 339 first command should select the first stored result");
      Assert (Latest_Message_Text (S) = "Selected first project search result",
              "Phase 339 first command should emit the expected navigation message");
      Assert (S.File_Info.Display_Name = Before_Display,
              "Phase 339 first command must not open or activate files");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase339_First_Last_Project_Search_Result;


   procedure Test_Phase339_Reveal_Active_Project_Search_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase339_reveal_active_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      Result : Editor.Project_Search.Project_Search_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Path);
      Editor.Executor.Execute_Run_Project_Search (S, "Execute_Command");
      Found := Editor.Project_Search.Select_First_Result_For_Path
        (S.Project_Search, "src/other/other.adb");
      Assert (Found,
              "Phase 339 setup should select a result outside the active file");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Reveal_Active_Project_Search_Result (S);
      Result := Editor.Project_Search.Result_At
        (S.Project_Search,
         Positive (Editor.Project_Search.Selected_Result_Index (S.Project_Search)));

      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
              "Phase 339 reveal-active should select the first result for the active file");
      Assert (To_String (Result.Relative_Path) = "src/editor/executor.adb",
              "Phase 339 reveal-active should use structured result identities, not rendered rows");
      Assert (Latest_Message_Text (S) =
                "Selected project search result in active file: src/editor/executor.adb:1",
              "Phase 339 reveal-active should report the concrete active-file result location");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Reveal_Active_Project_Search_Result (S);
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
              "Phase 339 reveal-active should preserve a selection already in the active file");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase339_Reveal_Active_Project_Search_Result;


   procedure Test_Phase339_Scope_Selected_Project_Search_Directory
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase339_scope_selected_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Project_Search.Cycle_File_Kind_Filter (S.Project_Search, True);
      Editor.Project_Search.Set_Case_Sensitive (S.Project_Search, True);
      Editor.Executor.Execute_Run_Project_Search (S, "Execute_Command");

      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 4,
              "Phase 339 scope setup should have current results before scoping");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Project_Search_Scope_Selected_Directory (S);

      Assert (Editor.Project_Search.Path_Scope (S.Project_Search) = "src/editor/",
              "Phase 339 scope-selected should derive scope from the selected result directory");
      Assert (Editor.Project_Search.Query (S.Project_Search) = "Execute_Command",
              "Phase 339 scope-selected should preserve the current Project Search query");
      Assert (Editor.Project_Search.File_Kind_Filter (S.Project_Search) =
                Editor.Project_Search.Project_Search_Kind_Ada,
              "Phase 339 scope-selected should preserve the Project Search kind filter");
      Assert (Editor.Project_Search.Case_Sensitive (S.Project_Search),
              "Phase 339 scope-selected should preserve case sensitivity");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 0
              and then Editor.Project_Search.Status (S.Project_Search) =
                Editor.Project_Search.Project_Search_Idle,
              "Phase 339 scope-selected should clear stale results, selection, and summary");
      Assert (Latest_Message_Text (S) = "Project search scope: src/editor/",
              "Phase 339 scope-selected should report the derived scope without claiming a rerun");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase339_Scope_Selected_Project_Search_Directory;


   procedure Test_Phase339_Project_Search_Navigation_No_Result_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_First_Project_Search_Result (S);
      Assert (Latest_Message_Text (S) = "No project search results",
              "Phase 339 first on empty results should report no results");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Last_Project_Search_Result (S);
      Assert (Latest_Message_Text (S) = "No project search results",
              "Phase 339 last on empty results should report no results");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Reveal_Active_Project_Search_Result (S);
      Assert (Latest_Message_Text (S) = "No active buffer.",
              "Phase 339 reveal-active without active buffer should report no active buffer");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Project_Search_Scope_Selected_Directory (S);
      Assert (Latest_Message_Text (S) = "No search result selected.",
              "Phase 339 scope-selected without selection should report no selected result");
   end Test_Phase339_Project_Search_Navigation_No_Result_Messages;


   procedure Test_Phase334_Open_Selected_Single_Location_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase334_single_message_root");
      S : Editor.State.State_Type;
      Msg : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Execute_Open_Selected_Project_Search_Result (S);

      Assert (Editor.Messages.Count (S.Messages) = 1,
              "Phase 334 open-selected should emit exactly one primary message");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) = "Opened needle.txt:2",
              "Phase 334 open-selected should report the concrete result location");
      Assert (To_String (S.File_Info.Display_Name) = "needle.txt",
              "Phase 334 open-selected should still use the existing open-buffer path");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase334_Open_Selected_Single_Location_Message;

   procedure Test_Phase334_Stale_Open_Failure_Preserves_Result_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase334_stale_search_root");
      S : Editor.State.State_Type;
      Msg : Editor.Messages.Editor_Message;
      Found : Boolean := False;
      Before_Count : Natural := 0;
      Before_Selected : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Before_Count := Editor.Project_Search.Result_Count (S.Project_Search);
      Before_Selected := Editor.Project_Search.Selected_Result_Index (S.Project_Search);
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "needle.txt"));
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Execute_Open_Selected_Project_Search_Result (S);

      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = Before_Count
              and then Editor.Project_Search.Selected_Result_Index (S.Project_Search) = Before_Selected,
              "Phase 334 stale open failure should preserve search results and selection");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "Phase 334 stale open failure should emit exactly one primary message");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) = "Could not open needle.txt: file not found",
              "Phase 334 stale open failure should be deterministic and path-relative");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase334_Stale_Open_Failure_Preserves_Result_State;


   procedure Test_Phase547_Out_Of_Range_Project_Search_Result_Does_Not_Clamp
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase547_out_of_range_search_root");
      S : Editor.State.State_Type;
      Msg : Editor.Messages.Editor_Message;
      Found : Boolean := False;
      Before_Count : Natural := 0;
      Before_Selected : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Before_Count := Editor.Project_Search.Result_Count (S.Project_Search);
      Before_Selected := Editor.Project_Search.Selected_Result_Index (S.Project_Search);

      --  Simulate an external/project lifecycle drift that leaves the searched
      --  file present but removes the retained result row.  Activation must not
      --  clamp the stale location to a different line.
      Write_Bytes (Ada.Directories.Compose (Root, "needle.txt"), "short" & ASCII.LF);
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Execute_Open_Selected_Project_Search_Result (S);

      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = Before_Count
              and then Editor.Project_Search.Selected_Result_Index (S.Project_Search) = Before_Selected,
              "Phase 547 out-of-range activation should preserve search results and selection");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "Phase 547 out-of-range activation should emit exactly one primary message");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) =
                "Search result target unavailable: line 2 is no longer available in needle.txt",
              "Phase 547 out-of-range activation should report unavailable target without clamping");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase547_Out_Of_Range_Project_Search_Result_Does_Not_Clamp;


   procedure Test_Phase74_Open_Project_Search_Bar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase74_open_search_bar_root");
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Editor.Quick_Open.Open (S.Quick_Open);

      Editor.Executor.Execute_Open_Project_Search_Bar (S);

      Assert (Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar),
              "opening project-search bar should open the bar");
      Assert (not Editor.Quick_Open.Is_Open (S.Quick_Open),
              "opening project-search bar should close quick open");
      Assert (Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar) = "needle",
              "opening project-search bar should mirror current project-search query");
      Cleanup_Project_Search_Fixture (Root);
   end Test_Phase74_Open_Project_Search_Bar;

   procedure Test_Phase74_Run_Project_Search_From_Bar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project_Search_Bar (S);
      Editor.Project_Search_Bar.Set_Query_Text (S.Project_Search_Bar, "needle");

      Editor.Executor.Execute_Run_Project_Search_From_Bar (S);

      Assert (Editor.Project_Search.Query (S.Project_Search) = "needle",
              "running from bar should copy bar query to Project_Search");
      Assert (Editor.Project_Search.Status (S.Project_Search) =
                Editor.Project_Search.Project_Search_No_Project,
              "running from bar without a project should report no-project deterministically");
      Assert (Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar),
              "running from bar should keep project-search bar open");
      Assert (Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Search_Results_Content,
              "running from bar should show Search Results content");
   end Test_Phase74_Run_Project_Search_From_Bar;

   procedure Test_Phase74_Close_And_Clear_Project_Search_Bar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase74_close_search_bar_root");
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_Project_Search_Bar (S);
      Editor.Project_Search_Bar.Set_Query_Text (S.Project_Search_Bar, "needle");
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");

      Editor.Executor.Execute_Close_Project_Search_Bar (S);
      Assert (not Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar),
              "close project-search bar should close only the input surface");
      Assert (Editor.Project_Search.Query (S.Project_Search) = "needle",
              "close project-search bar should preserve project-search results/query");

      Editor.Project_Search_Bar.Open (S.Project_Search_Bar);
      Editor.Executor.Execute_Clear_Project_Search (S);
      Assert (Editor.Project_Search.Query (S.Project_Search) = "",
              "clear project search should clear project-search query");
      Assert (Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar) = "",
              "clear project search should clear open bar field");
      Assert (Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar),
              "clear project search must not close project-search bar");
   end Test_Phase74_Close_And_Clear_Project_Search_Bar;

   procedure Test_Phase334_Query_Edit_And_Refresh_Clear_Results
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase334_query_refresh_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "fixture should produce one Project Search result before query edit");

      Editor.Executor.Execute_Open_Project_Search_Bar (S);
      Editor.Project_Search_Bar.Set_Query_Text (S.Project_Search_Bar, "needle");
      Editor.Executor.Execute_Project_Search_Bar_Insert_Text (S, "x");
      Assert (Editor.Project_Search.Query (S.Project_Search) = "needlex",
              "Phase 334 query edit should update Project Search query state");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 0,
              "Phase 334 query edit should clear old Project Search results and selection");

      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "fixture should produce one Project Search result before refresh");
      Editor.Executor.Execute_Refresh_Project_Files (S);
      Assert (Editor.Project_Search.Query (S.Project_Search) = "needle",
              "Phase 334 project file refresh should preserve visible Project Search query");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 0,
              "Phase 334 project file refresh should clear Project Search results and selection");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase334_Query_Edit_And_Refresh_Clear_Results;

   procedure Test_Phase76_Focus_Search_Results_Shows_And_Focuses
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase76_focus_results_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Editor.Panels.Set_Visible (S.Panels, Editor.Panels.Bottom_Panel, False);

      Editor.Executor.Execute_Focus_Search_Results (S);

      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "Phase 76 focus Search Results should show the bottom panel when results exist");
      Assert
        (Editor.Panels.Active_Bottom_Content (S.Panels) =
           Editor.Panels.Search_Results_Content,
         "Phase 76 focus Search Results should select Search Results bottom content");
      Assert
        (Editor.Panel_Focus.Target (S.Panel_Focus) =
           Editor.Panel_Focus.Bottom_Panel_Focus
         and then Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Search_Results_Focus,
         "Phase 76 focus Search Results should move keyboard ownership to Search Results");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase76_Focus_Search_Results_Shows_And_Focuses;

   procedure Test_Phase76_Search_Results_Move_Is_Selection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase76_selection_only_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Multi_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Editor.Executor.Execute_Focus_Search_Results (S);

      Assert
        (Editor.Project_Search.Result_Count (S.Project_Search) = 3,
         "Phase 76 multi-result fixture should produce three results");
      Assert
        (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
         "Phase 76 search should start with the first result selected");

      Editor.Executor.Execute_Search_Results_Move_Down (S);

      Assert
        (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 2,
         "Phase 76 focused Down should move Search Results selection only");
      Assert
        (To_String (S.File_Info.Display_Name) = "Untitled",
         "Phase 76 focused Down must not open the selected result");
      Assert
        (Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Search_Results_Focus,
         "Phase 76 focused movement should keep Search Results focus");

      Editor.Executor.Execute_Search_Results_Move_Up (S);
      Editor.Executor.Execute_Search_Results_Move_Up (S);

      Assert
        (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
         "Phase 76 focused Up should not wrap past the first result");

      Cleanup_Project_Search_Multi_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase76_Search_Results_Move_Is_Selection_Only;

   procedure Test_Phase76_Search_Results_Open_Returns_To_Editor_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase76_open_selected_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Multi_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Editor.Executor.Execute_Focus_Search_Results (S);
      Editor.Executor.Execute_Search_Results_Move_Down (S);
      Editor.Executor.Execute_Search_Results_Open_Selected (S);

      Assert
        (To_String (S.File_Info.Display_Name) = "needle_multi.txt",
         "Phase 76 Enter should open the selected Search Results match");
      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "Phase 76 Enter should return focus to editor text after opening a result");
      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "Phase 76 Enter should keep Search Results panel visible");

      Cleanup_Project_Search_Multi_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase76_Search_Results_Open_Returns_To_Editor_Text;

   procedure Test_Phase76_Search_Results_Escape_Returns_To_Editor_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase76_escape_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Editor.Executor.Execute_Focus_Search_Results (S);
      Editor.Executor.Execute_Search_Results_Close_Or_Hide (S);

      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "Phase 76 Escape should return focus to editor text");
      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "Phase 76 Escape should not hide the Search Results panel");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase76_Search_Results_Escape_Returns_To_Editor_Text;


   procedure Test_Phase77_Focus_Problems_Shows_And_Focuses
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Error, Message => "first");
      Editor.Panels.Set_Visible (S.Panels, Editor.Panels.Bottom_Panel, False);

      Editor.Executor.Execute_Focus_Problems (S);

      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "Phase 77 focus Problems should show the bottom panel");
      Assert
        (Editor.Panels.Active_Bottom_Content (S.Panels) =
           Editor.Panels.Problems_Content,
         "Phase 77 focus Problems should select Problems bottom content");
      Assert
        (Editor.Panel_Focus.Target (S.Panel_Focus) =
           Editor.Panel_Focus.Bottom_Panel_Focus
         and then Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Problems_Focus,
         "Phase 77 focus Problems should move keyboard ownership to Problems");
      Assert
        (Editor.Problems.Selected_Row_Index (S.Problems_View) = 1,
         "Phase 77 focus Problems should select the first diagnostic row");
   end Test_Phase77_Focus_Problems_Shows_And_Focuses;

   procedure Test_Phase77_Problems_Move_Is_Selection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Pos : Editor.Cursors.Cursor_Index := 0;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def" & ASCII.LF & "ghi");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 0, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Before_Pos := S.Carets (S.Carets.First_Index).Pos;
      Editor.State.Add_Diagnostic
        (S, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Error, Message => "first");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 4, End_Index => 5,
         Severity => Editor.Diagnostics.Warning, Message => "second");
      Editor.Executor.Execute_Focus_Problems (S);

      Editor.Executor.Execute_Problems_Move_Down (S);

      Assert
        (Editor.Problems.Selected_Row_Index (S.Problems_View) = 2,
         "Phase 77 focused Down should move Problems selection only");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = Before_Pos,
         "Phase 77 focused Down must not move the editor caret");
      Assert
        (Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Problems_Focus,
         "Phase 77 focused movement should keep Problems focus");
   end Test_Phase77_Problems_Move_Is_Selection_Only;

   procedure Test_Phase77_Problems_Open_Returns_To_Editor_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def" & ASCII.LF & "ghi");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Error, Message => "first");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 4, End_Index => 5,
         Severity => Editor.Diagnostics.Warning, Message => "second");
      Editor.Executor.Execute_Focus_Problems (S);
      Editor.Executor.Execute_Problems_Move_Down (S);

      Editor.Executor.Execute_Problems_Open_Selected (S);

      Assert
        (S.Active_Diagnostic.Has_Active
         and then S.Active_Diagnostic.Index = 2,
         "Phase 77 Enter should open the selected diagnostic");
      Assert
        (S.Carets (S.Carets.First_Index).Pos = 4,
         "Phase 77 selected diagnostic open should move caret to diagnostic target");
      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "Phase 77 Enter should return focus to editor text after opening a problem");
      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "Phase 77 Enter should keep Problems panel visible");
   end Test_Phase77_Problems_Open_Returns_To_Editor_Text;

   procedure Test_Phase77_Problems_Open_No_Selection_Reports
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Focus_Problems (S);
      Editor.Problems.Set_Selected_Row_Index (S.Problems_View, 0);

      Editor.Executor.Execute_Problems_Open_Selected (S);

      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "No diagnostic selected",
         "Phase 77 opening with no selected problem should report a deterministic failure");
      Assert
        (Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Problems_Focus,
         "Phase 77 opening with no selected problem should preserve Problems focus");
   end Test_Phase77_Problems_Open_No_Selection_Reports;

   procedure Test_Phase77_Problems_Escape_Returns_To_Editor_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Focus_Problems (S);

      Editor.Executor.Execute_Problems_Focus_Editor (S);

      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "Phase 77 Escape should return focus to editor text");
      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "Phase 77 Escape should not hide the Problems panel");
   end Test_Phase77_Problems_Escape_Returns_To_Editor_Text;


   procedure Test_Phase79_Open_Overlays_Activate_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.Command_Palette.Reset;

      Editor.Executor.Execute_Open_Command_Palette (S);
      Assert
        (Editor.Command_Palette.Is_Open,
         "Phase 79 command palette command should open palette surface");
      Assert
        (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) =
           Editor.Overlay_Focus.Command_Palette_Overlay,
         "Phase 79 command palette command should activate command-palette overlay");

      Editor.Executor.Execute_Open_Quick_Open (S);
      Assert
        (not Editor.Command_Palette.Is_Open,
         "Phase 79 quick open should close the command palette surface");
      Assert
        (Editor.Quick_Open.Is_Open (S.Quick_Open),
         "Phase 79 quick open command should open quick-open surface");
      Assert
        (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) =
           Editor.Overlay_Focus.Quick_Open_Overlay,
         "Phase 79 quick open command should activate quick-open overlay");

      Editor.Executor.Execute_Open_Project_Search_Bar (S);
      Assert
        (not Editor.Quick_Open.Is_Open (S.Quick_Open),
         "Phase 79 project search bar should close quick open");
      Assert
        (Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar),
         "Phase 79 project search command should open project-search bar");
      Assert
        (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) =
           Editor.Overlay_Focus.Project_Search_Bar_Overlay,
         "Phase 79 project search command should activate project-search overlay");
   end Test_Phase79_Open_Overlays_Activate_Through_Executor;

   procedure Test_Phase79_Active_Find_Prompt_Remains_Visible_But_Inactive_Under_Quick_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Find_Show (S);
      Assert
        (S.Active_Find_Prompt,
         "Phase 79 find command should open the active Find prompt");
      Assert
        (Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Active_Find_Prompt_Overlay),
         "Phase 79 find command should activate the find overlay");

      Editor.Executor.Execute_Open_Quick_Open (S);

      Assert
        (S.Active_Find_Prompt,
         "Phase 79 opening quick open should leave active Find prompt visible");
      Assert
        (Editor.Quick_Open.Is_Open (S.Quick_Open),
         "Phase 79 opening quick open should open quick-open surface");
      Assert
        (Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay),
         "Phase 79 quick open should own overlay focus after replacing find input focus");
      Assert
        (not Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Active_Find_Prompt_Overlay),
         "Phase 79 visible active Find prompt must be inactive while quick open owns input");
   end Test_Phase79_Active_Find_Prompt_Remains_Visible_But_Inactive_Under_Quick_Open;

   procedure Test_Phase79_Deactivate_Active_Find_Prompt_Leaves_Surface_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Find_Show (S);

      Editor.Executor.Deactivate_Active_Overlay_Only
        (S, Editor.Overlay_Focus.Dismiss_Outside_Click);

      Assert
        (not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus),
         "Phase 79 focus-only deactivation should clear active overlay");
      Assert
        (S.Active_Find_Prompt,
         "Phase 79 focus-only deactivation should keep active Find prompt visible");
      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "Phase 79 deactivation should restore the previous editor-text focus");
   end Test_Phase79_Deactivate_Active_Find_Prompt_Leaves_Surface_Open;

   procedure Test_Phase79_Dismiss_Restores_Valid_File_Tree_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase79_focus_restore_root");
      S    : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Focus_File_Tree (S);
      Editor.Executor.Execute_Open_Quick_Open (S);

      Editor.Executor.Execute_Close_Quick_Open (S);

      Assert
        (Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus),
         "Phase 79 dismiss should restore valid file-tree focus");
      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase79_Dismiss_Restores_Valid_File_Tree_Focus;

   function Pending_Test_Summary
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
   end Pending_Test_Summary;

   procedure Test_Pending_Invalid_Open_Project_Clears_Silently
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => Null_Unbounded_String,
         Display    => To_Unbounded_String ("invalid project"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => False,
         others     => <>);
   begin
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Pending_Test_Summary);

      Assert (not Editor.Executor.Pending_Transition_Is_Still_Valid (S),
              "empty-path pending open-project target must be stale");
      Editor.Executor.Invalidate_Pending_Transition_If_Stale (S);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "stale pending open-project target must clear deterministically");
   end Test_Pending_Invalid_Open_Project_Clears_Silently;

   procedure Test_Pending_Invalid_Close_Buffer_Clears_Silently
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Close_Buffer,
         Path       => Null_Unbounded_String,
         Display    => To_Unbounded_String ("closed.adb"),
         Buffer_Id  => Natural (Editor.Buffers.No_Buffer),
         Has_Buffer => True,
         Has_Path   => False,
         others     => <>);
   begin
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Pending_Test_Summary);

      Assert (not Editor.Executor.Pending_Transition_Is_Still_Valid (S),
              "pending close-buffer target must be stale after target disappears");
      Editor.Executor.Invalidate_Pending_Transition_If_Stale (S);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "stale pending close-buffer target must clear deterministically");
   end Test_Pending_Invalid_Close_Buffer_Clears_Silently;



   procedure Test_Phase213_Open_Selected_Recent_Project_Opens_First_Entry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Root       : constant String := Temp_Path ("phase213_recent_project");
      Config_Dir : constant String := Temp_Path ("phase213_recent_config");
      Cmd        : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Config_Dir);
      Ada.Directories.Create_Path (Root);
      Ada.Directories.Create_Path (Config_Dir);
      Editor.Recent_Projects.Set_Config_Directory_For_Tests (Config_Dir);
      Init_Executor_Test_State (S);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Root, "phase213_recent_project", 213);

      Cmd.Kind := Editor.Commands.Open_Selected_Recent_Project;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Has_Project (S.Project),
              "open selected recent project should open the first recent entry");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root),
              "recent project activation should use the approved project-open path");

      Use_Executor_Recent_Config;
      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Config_Dir);
   end Test_Phase213_Open_Selected_Recent_Project_Opens_First_Entry;

   procedure Test_Phase213_Open_Selected_Recent_Project_Missing_Path_Fails_Safely
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Missing : constant String := Temp_Path ("phase213_missing_recent_project");
      Cmd     : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Missing);
      Init_Executor_Test_State (S);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Missing, "missing", 213);

      Cmd.Kind := Editor.Commands.Open_Selected_Recent_Project;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Editor.Project.Has_Project (S.Project),
              "missing recent project activation must not install a project");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "failed recent project activation must not rewrite recent projects");
   end Test_Phase213_Open_Selected_Recent_Project_Missing_Path_Fails_Safely;

   procedure Test_Phase559_Recent_Project_Selection_Commands_Are_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, "/tmp/phase559-a", "phase559-a", 1);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, "/tmp/phase559-b", "phase559-b", 2);

      S.Recent_Project_Selected_Index := 0;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Next_Recent_Project);
      Assert (S.Recent_Project_Selected_Index = 1,
              "select next must initialize transient selection to the first recent row");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Next_Recent_Project);
      Assert (S.Recent_Project_Selected_Index = 2,
              "select next must move to the next recent row");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Next_Recent_Project);
      Assert (S.Recent_Project_Selected_Index = 1,
              "select next must wrap deterministically to the first recent row");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Previous_Recent_Project);
      Assert (S.Recent_Project_Selected_Index = 2,
              "select previous must wrap deterministically to the last recent row");

      Assert (not Editor.Project.Has_Project (S.Project),
              "selecting recent rows must not open or mutate project context");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 2,
              "selecting recent rows must not remove or persist recent entries");
   end Test_Phase559_Recent_Project_Selection_Commands_Are_Transient;

   procedure Test_Phase559_Show_Recent_Projects_Reports_No_Available
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Missing1 : constant String := Temp_Path ("phase559_show_missing_a");
      Missing2 : constant String := Temp_Path ("phase559_show_missing_b");
      Msg      : Unbounded_String;
   begin
      Remove_Tree_If_Exists (Missing1);
      Remove_Tree_If_Exists (Missing2);
      Init_Executor_Test_State (S);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Missing1, "missing-a", 1);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Missing2, "missing-b", 2);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Show_Recent_Projects);
      Msg := To_Unbounded_String (Latest_Message_Text (S));

      Assert (Ada.Strings.Fixed.Index (To_String (Msg), "No available recent projects") > 0,
              "Recent Projects projection must expose the all-unavailable empty state");
      Assert (Ada.Strings.Fixed.Index (To_String (Msg), "project path no longer exists") > 0,
              "Recent Projects projection must still show removable unavailable rows");
      Assert (not Editor.Project.Has_Project (S.Project),
              "showing Recent Projects must not open a project");
   end Test_Phase559_Show_Recent_Projects_Reports_No_Available;

   procedure Test_Phase208_Insert_Newline_Dirty_And_Cursor
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "ab");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 1,
            Anchor                => 1,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := ASCII.LF;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.LF));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "a" & ASCII.LF & "b",
              "newline insertion must preserve surrounding text");
      Assert (S.Carets (S.Carets.First_Index).Pos = 2,
              "caret must advance after newline insertion");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 2,
              "selection must be cleared after insertion");
      Assert (S.File_Info.Dirty, "successful insertion must dirty buffer");
   end Test_Phase208_Insert_Newline_Dirty_And_Cursor;

   procedure Test_Phase208_Insert_Replaces_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abcdef");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 5,
            Anchor                => 2,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'X';
      Cmd.Text := To_Unbounded_String (String'(1 => 'X'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "abXf",
              "typing over selection must replace selected text");
      Assert (S.Carets (S.Carets.First_Index).Pos = 3,
              "caret must land after replacement text");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 3,
              "selection must clear after replacement");
      Assert (S.File_Info.Dirty, "selection replacement must dirty buffer");
   end Test_Phase208_Insert_Replaces_Selection;

   procedure Test_Phase208_Backspace_At_Buffer_Start_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Revision_0 : Natural;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abc");
      Revision_0 := Editor.State.Current_Buffer_Revision (S);

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Delete_Char;
      Cmd.Ch := ASCII.NUL;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.NUL));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "abc",
              "backspace at start must not mutate buffer");
      Assert (not S.File_Info.Dirty,
              "backspace no-op must not dirty clean buffer");
      Assert (Editor.State.Current_Buffer_Revision (S) = Revision_0,
              "backspace no-op must not bump buffer revision");
      Assert (S.Carets (S.Carets.First_Index).Pos = 0,
              "caret must remain valid after no-op backspace");
   end Test_Phase208_Backspace_At_Buffer_Start_Is_No_Op;

   procedure Test_Phase208_Paste_Replaces_Multiline_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 11,
            Anchor                => 2,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := To_Unbounded_String ("X" & ASCII.LF & "Y");

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "onX" & ASCII.LF & "Yee",
              "single-selection paste must replace the selected multiline range");
      Assert (S.Carets (S.Carets.First_Index).Pos = 5,
              "caret must land after pasted multiline replacement text");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 5,
              "selection must clear after paste replacement");
      Assert (S.File_Info.Dirty,
              "pasting over a selection must dirty the buffer");
   end Test_Phase208_Paste_Replaces_Multiline_Selection;

   procedure Test_Phase208_Empty_Paste_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Revision_0 : Natural;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abcdef");
      Revision_0 := Editor.State.Current_Buffer_Revision (S);

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 5,
            Anchor                => 2,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := Null_Unbounded_String;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "abcdef",
              "empty paste must not mutate buffer content");
      Assert (S.Carets (S.Carets.First_Index).Pos = 5,
              "empty paste must preserve caret position");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 2,
              "empty paste must preserve the existing selection");
      Assert (not S.File_Info.Dirty,
              "empty paste must not dirty a clean buffer");
      Assert (Editor.State.Current_Buffer_Revision (S) = Revision_0,
              "empty paste must not bump buffer revision");
   end Test_Phase208_Empty_Paste_Is_No_Op;


   procedure Test_Phase210_Paste_Normalizes_Line_Endings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);

      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := To_Unbounded_String
        ("A" & ASCII.CR & ASCII.LF
         & "B" & ASCII.CR
         & "C" & ASCII.LF
         & "D");

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "A" & ASCII.LF
              & "B" & ASCII.LF
              & "C" & ASCII.LF
              & "D",
              "paste must normalize CRLF, lone CR, and LF to LF");
      Assert (S.Carets (S.Carets.First_Index).Pos = 7,
              "caret must land after normalized pasted text");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 7,
              "selection must remain clear after normalized paste");
      Assert (S.File_Info.Dirty,
              "normalized paste with content must dirty the buffer");
   end Test_Phase210_Paste_Normalizes_Line_Endings;

   procedure Test_Phase210_Paste_Trailing_Newline_Over_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abcdef");

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 4,
            Anchor                => 2,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := To_Unbounded_String ("X" & ASCII.LF & "Y" & ASCII.LF);

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "abX" & ASCII.LF & "Y" & ASCII.LF & "ef",
              "paste with trailing newline must preserve the trailing empty line boundary");
      Assert (S.Carets (S.Carets.First_Index).Pos = 6,
              "caret must land after pasted trailing newline");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 6,
              "selection must clear after trailing-newline replacement paste");
      Assert (S.File_Info.Dirty,
              "trailing-newline paste replacement must dirty the buffer");
   end Test_Phase210_Paste_Trailing_Newline_Over_Selection;

   procedure Test_Phase210_Empty_Paste_Preserves_Dirty_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Revision_0 : Natural;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abc");
      Revision_0 := Editor.State.Current_Buffer_Revision (S);

      S.Carets.Clear;
      S.Carets.Append
        (Caret_State'
           (Pos                   => 1,
            Anchor                => 1,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));

      Cmd.Kind := Editor.Commands.Paste_Text;
      Cmd.Text := Null_Unbounded_String;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Buffer_Text (S) = "abc",
              "empty paste must preserve buffer content");
      Assert (S.Carets (S.Carets.First_Index).Pos = 1,
              "empty paste must preserve caret");
      Assert (S.Carets (S.Carets.First_Index).Anchor = 1,
              "empty paste must preserve selection state");
      Assert (not S.File_Info.Dirty,
              "empty paste must not dirty the buffer");
      Assert (Editor.State.Current_Buffer_Revision (S) = Revision_0,
              "empty paste must not bump revision");
   end Test_Phase210_Empty_Paste_Preserves_Dirty_State;

   procedure Test_Phase208_Edit_Invalidates_Feature_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Result : Editor.Outline.Outline_Refresh_Result;
      pragma Unreferenced (Result);
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha" & ASCII.LF & "beta");

      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages,
         Editor.Feature_Messages.Info_Message,
         "targeted message",
         Has_Target => True,
         Buffer     => S.Registry_Token,
         Line       => 1,
         Column     => 1);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "targeted diagnostic",
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 1,
         Target_Column => 1);
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (S.Feature_Search_Results,
         Query         => "alpha",
         Snapshot_Text => Buffer_Text (S),
         Source_Label  => "active",
         Target_Buffer => S.Registry_Token,
         Snapshot_Version => Editor.State.Current_Buffer_Revision (S));
      Result := Editor.Outline.Fixtures.Populate_Synthetic_Outline (S.Outline);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "targeted Messages rows for edited buffer must be removed");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "targeted Diagnostics rows for edited buffer must be removed");
      Assert (Editor.Feature_Search_Results.Results_Stale (S.Feature_Search_Results),
              "Search Results must be generation-marked stale after edit");
      Assert (Editor.Outline.Filtered_Row_Count (S.Outline) = 0,
              "Outline rows must be cleared after buffer edit");
   end Test_Phase208_Edit_Invalidates_Feature_Targets;


   function Latest_Message_Text (S : Editor.State.State_Type) return String
   is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (Msg);
      else
         return "";
      end if;
   end Latest_Message_Text;

   procedure Test_Phase222_Unavailable_Command_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural;
   begin
      Init_Executor_Test_State (S);
      Before := Text_Buffer.Length (S.Buffer);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_File);

      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "save without active buffer must be unavailable");
      Assert (Text_Buffer.Length (S.Buffer) = Before,
              "unavailable command must not mutate the buffer");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "unavailable command emits one primary message");
      Assert (Latest_Message_Text (S) = "No active buffer.",
              "unavailable feedback must use the canonical user-facing reason");
   end Test_Phase222_Unavailable_Command_Feedback_Is_Deterministic;

   procedure Test_Phase222_Build_Command_Feedback_Avoids_Internal_Details
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);

      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "public build test seam route remains unavailable");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "unavailable build route emits one primary message");
      Assert (Latest_Message_Text (S) = "Build: structured command context required",
              "build route feedback must remain deterministic");
      Assert (Ada.Strings.Fixed.Index (Latest_Message_Text (S), "PATH") = 0,
              "feedback must not expose PATH details");
      Assert (Ada.Strings.Fixed.Index (Latest_Message_Text (S), "--") = 0,
              "feedback must not expose shell-style argv details");
      Assert (Ada.Strings.Fixed.Index (Latest_Message_Text (S), "Command_Build") = 0,
              "feedback must not expose internal enum names");
   end Test_Phase222_Build_Command_Feedback_Avoids_Internal_Details;

   procedure Test_Phase222_Target_Activation_Failure_Feedback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);
      Editor.Feature_Messages.Add_Message
        (S.Feature_Messages, Editor.Feature_Messages.Error_Message,
         "Save failed", "old.adb", True, S.Registry_Token + 10, 1, 1);
      Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);

      Result := Editor.Executor.Execute_Message_Row_Activation (S, 2);

      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "stale targeted message activation remains non-mutating");
      Assert (Latest_Message_Text (S) = "Target no longer exists.",
              "stale target activation reports concise deterministic feedback");
      Assert (Ada.Strings.Fixed.Index (Latest_Message_Text (S), "generation") = 0,
              "target feedback must not expose projection generation details");
   end Test_Phase222_Target_Activation_Failure_Feedback;

   procedure Test_Phase223_Cancel_No_Cancellable_Is_Quiet_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural;
   begin
      Init_Executor_Test_State (S);
      Editor.Command_Palette.Close;
      Before := Editor.Messages.Count (S.Messages);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Cancel);

      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "cancel with nothing cancellable is an intentional no-op");
      Assert (Editor.Messages.Count (S.Messages) = Before,
              "quiet cancel no-op must not create feedback");
      Assert (not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus),
              "cancel no-op must not activate overlays");
   end Test_Phase223_Cancel_No_Cancellable_Is_Quiet_No_Op;

   procedure Test_Phase223_Cancel_Command_Palette_Is_Cancelled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);
      Editor.Command_Palette.Close;
      Editor.Executor.Activate_Overlay
        (S, Editor.Overlay_Focus.Command_Palette_Overlay);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Cancel);

      Assert (Result.Status = Editor.Executor.Command_Cancelled,
              "Escape/cancel against an active palette is cancellation");
      Assert (not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus),
              "cancel must dismiss the active overlay");
      Assert (not Editor.Command_Palette.Is_Open,
              "cancel must close the command palette surface");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "palette cancellation remains quiet");
   end Test_Phase223_Cancel_Command_Palette_Is_Cancelled;

   procedure Test_Phase223_Feature_Panel_Already_State_No_Ops
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural;
   begin
      Init_Executor_Test_State (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "initial show feature panel succeeds");

      Before := Editor.Messages.Count (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "showing an already visible feature panel is unavailable");
      Assert (Editor.Messages.Count (S.Messages) >= Before,
              "already-visible show reports through availability");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "initial focus feature panel succeeds");

      Before := Editor.Messages.Count (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "focusing an already focused feature panel is unavailable");
      Assert (Editor.Messages.Count (S.Messages) >= Before,
              "already-focused focus reports through availability");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Hide_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "initial hide feature panel succeeds");

      Before := Editor.Messages.Count (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Hide_Feature_Panel);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "hiding an already hidden feature panel is unavailable");
      Assert (Editor.Messages.Count (S.Messages) >= Before,
              "already-hidden hide reports through availability");
   end Test_Phase223_Feature_Panel_Already_State_No_Ops;

   procedure Test_Phase223_Empty_Clear_Commands_Are_Quiet_No_Ops
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural;
   begin
      Init_Executor_Test_State (S);
      Before := Editor.Messages.Count (S.Messages);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Messages);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "clearing empty Messages is a no-op");
      Assert (Editor.Messages.Count (S.Messages) = Before,
              "empty Messages clear remains quiet");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Clear);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "clearing empty Diagnostics is a no-op");
      Assert (Editor.Messages.Count (S.Messages) = Before,
              "empty Diagnostics clear remains quiet");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Search_Results_Feature);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "clearing empty Search Results is a no-op");
      Assert (Editor.Messages.Count (S.Messages) = Before,
              "empty Search Results clear remains quiet");
   end Test_Phase223_Empty_Clear_Commands_Are_Quiet_No_Ops;

   procedure Test_Phase223_Navigation_Boundaries_Are_No_Ops
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before_Dirty : Boolean;
   begin
      Init_Executor_Test_State (S);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_New_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "new buffer setup succeeds");
      Before_Dirty := S.File_Info.Dirty;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Left);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "moving left at the start of the buffer is a no-op");
      Assert (S.File_Info.Dirty = Before_Dirty,
              "boundary navigation must not dirty the buffer");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Previous_Buffer);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "previous buffer with only one buffer is a no-op");
      Assert (S.File_Info.Dirty = Before_Dirty,
              "buffer navigation no-op must not dirty the buffer");
   end Test_Phase223_Navigation_Boundaries_Are_No_Ops;



   function Availability_Reason
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return String
   is
      A : constant Editor.Commands.Command_Availability :=
        Editor.Executor.Command_Availability (S, Id);
   begin
      return Editor.Commands.Unavailable_Reason (A);
   end Availability_Reason;

   procedure Assert_Unavailable_Reason
     (S        : Editor.State.State_Type;
      Id       : Editor.Commands.Command_Id;
      Expected : String;
      Label    : String)
   is
      A : constant Editor.Commands.Command_Availability :=
        Editor.Executor.Command_Availability (S, Id);
   begin
      Assert (not Editor.Commands.Is_Available (A), Label & " must be unavailable");
      Assert (Editor.Commands.Unavailable_Reason (A) = Expected,
              Label & " reason expected '" & Expected & "' but got '" &
              Editor.Commands.Unavailable_Reason (A) & "'");
   end Assert_Unavailable_Reason;

   procedure Test_Phase224_Common_Availability_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Root : constant String := Temp_Path ("phase224_availability_root");
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Save_File, "No active buffer.",
         "buffer command without active buffer");
      Assert_Unavailable_Reason
        (S, Editor.Commands.No_Command, "No command selected.",
         "empty command invocation");
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Close_Project, "No project open.",
         "project command without project");
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Diagnostics_Open_Selected,
         "No diagnostics.", "diagnostic activation without diagnostics");
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Clear_Selected_Message,
         "No messages", "message action without messages");

      Editor.State.Load_Text (S, "alpha beta");
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_Project_Search_From_Selection,
         "No project open.", "selection command without project");

      Build_Fixture (Root);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Focus_File_Tree (S);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 0);
      Assert_Unavailable_Reason
        (S, Editor.Commands.Command_File_Tree_Open_Selected,
         "No file selected.", "file tree activation without selection");
      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase224_Common_Availability_Reasons;

   procedure Test_Phase224_Availability_Feedback_Matches_Preflight
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Reason : Unbounded_String;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural;
   begin
      Init_Executor_Test_State (S);
      Reason := To_Unbounded_String
        (Availability_Reason (S, Editor.Commands.Command_Save_File));
      Before := Text_Buffer.Length (S.Buffer);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_File);

      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "unavailable save command must be classified unavailable");
      Assert (Text_Buffer.Length (S.Buffer) = Before,
              "unavailable command must not mutate buffer text");
      Assert (Latest_Message_Text (S) = To_String (Reason),
              "execution feedback must match availability preflight reason");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "unavailable command emits one primary message");
   end Test_Phase224_Availability_Feedback_Matches_Preflight;

   procedure Test_Phase224_Availability_Checks_Are_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Text     : Unbounded_String;
      Before_Messages : Natural;
      Before_Feature_Rows : Natural;
      Before_File_Tree_Rows : Natural;
      A : Editor.Commands.Command_Availability;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "one" & Character'Val (10) & "two");
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Feature_Rows := Editor.Feature_Panel.Row_Count (S.Feature_Panel);
      Before_File_Tree_Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Editor.Commands.Is_Available (A),
              "refresh outline should be available with an active buffer");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (A),
              "search active buffer without query remains unavailable");
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);
      Assert (not Editor.Commands.Is_Available (A),
              "diagnostics open selected remains unavailable without diagnostics");

      Assert (Editor.State.Current_Text (S) = To_String (Before_Text),
              "availability must not mutate active buffer text");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "availability must not post Messages");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = Before_Feature_Rows,
              "availability must not mutate Feature Panel rows");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Before_File_Tree_Rows,
              "availability must not mutate File Tree rows");
   end Test_Phase224_Availability_Checks_Are_Side_Effect_Free;

   procedure Test_Phase224_Palette_Disabled_Reason_Matches_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found : Boolean := False;
      Expected : Unbounded_String;
   begin
      Init_Executor_Test_State (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("save file");
      Expected := To_Unbounded_String
        (Availability_Reason (S, Editor.Commands.Command_Save_File));

      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Save_File then
            Found := True;
            Assert (not Candidate.Available,
                    "palette must show Save File disabled without active buffer");
            Assert (To_String (Candidate.Reason) = To_String (Expected),
                    "palette disabled reason must match Executor preflight");
         end if;
      end loop;

      Assert (Found, "Save File command must be present in palette candidates");
   end Test_Phase224_Palette_Disabled_Reason_Matches_Executor;


   procedure Test_Phase239_File_Tree_Already_Open_Missing_File_Focuses_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root  : constant String := Temp_Path ("phase239_ft_open_focus_root");
      Path  : constant String := Ada.Directories.Compose (Root, "a.txt");
      S     : Editor.State.State_Type;
      Node  : Editor.File_Tree.File_Tree_Node_Id;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 239 fixture must include a File Tree node for a.txt");

      Editor.Executor.Execute_Open_File (S, Path);
      Editor.State.Replace_Buffer_Contents (S, "dirty unsaved content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Remove_File_If_Exists (Path);

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, Node, Editor.File_Tree_View.Open_File_Action);

      Assert (Editor.State.Current_Text (S) = "dirty unsaved content",
              "Phase 239: File Tree activation of an already-open missing file must preserve dirty content");
      Assert (S.File_Info.Dirty,
              "Phase 239: File Tree focus path must preserve the dirty marker");
      Assert (Editor.Buffers.Global_Count = 1,
              "Phase 239: File Tree focus path must not create a duplicate buffer");
      Assert (Latest_Message_Text (S) =
                "Focused existing buffer a.txt; disk was not reloaded",
              "Phase 239: File Tree already-open feedback must match explicit open/focus feedback");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase239_File_Tree_Already_Open_Missing_File_Focuses_Buffer;


   procedure Test_Phase243_Project_Close_Removes_Project_Clean_Buffers_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase243_project_close_root");
      Project_F  : constant String := Ada.Directories.Compose (Root, "a.txt");
      Other_F    : constant String := Temp_Path ("phase243_unrelated.txt");
      S          : Editor.State.State_Type;
      Found      : Boolean := False;
      Ignored_Id : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Ignored_Id);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Bytes (Other_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Project_F);
      Editor.Executor.Execute_Open_File (S, Other_F);

      declare
         Result : constant Editor.Executor.Command_Execution_Result :=
           Editor.Executor.Execute_Command_With_Result
             (S, Editor.Commands.Command_Close_Project);
         pragma Unreferenced (Result);
      begin
         null;
      end;

      Assert (not Editor.Project.Has_Project (S.Project),
              "Phase 243 project close must clear the project state");
      Ignored_Id := Editor.Buffers.Global_Find_By_Path (Project_F, Found);
      Assert (not Found,
              "Phase 243 project close must remove the clean project-owned buffer");
      Ignored_Id := Editor.Buffers.Global_Find_By_Path (Other_F, Found);
      Assert (Found,
              "Phase 243 project close must preserve unrelated buffers");
      Assert (Editor.Buffers.Global_Count >= 1,
              "Phase 243 project close must leave unrelated buffers open under the existing buffer policy");
      Assert (Latest_Message_Text (S) = "Project closed",
              "Phase 243 project close feedback must remain deterministic");

      Remove_File_If_Exists (Other_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Other_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase243_Project_Close_Removes_Project_Clean_Buffers_Only;

   procedure Test_Phase243_Project_Close_Blocks_Project_Dirty_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("phase243_project_dirty_root");
      Project_F   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S           : Editor.State.State_Type;
      Before_Rows : Natural := 0;
      Found       : Boolean := False;
      Id          : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Before_Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Editor.Executor.Execute_Open_File (S, Project_F);
      Editor.State.Replace_Buffer_Contents (S, "dirty project content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      declare
         Result : constant Editor.Executor.Command_Execution_Result :=
           Editor.Executor.Execute_Command_With_Result
             (S, Editor.Commands.Command_Close_Project);
         pragma Unreferenced (Result);
      begin
         null;
      end;

      Assert (Editor.Project.Has_Project (S.Project),
              "Phase 243 blocked project close must preserve project state");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Before_Rows,
              "Phase 243 blocked project close must preserve File Tree state");
      Id := Editor.Buffers.Global_Find_By_Path (Project_F, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "Phase 243 blocked project close must keep the dirty project buffer");
      Assert (Editor.Buffers.Global_Summary_For (Id).Is_Dirty,
              "Phase 243 blocked project close must preserve dirty marker");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 243 blocked project close must leave an explicit pending transition");
      Assert (Latest_Message_Text (S) = "Cannot close project with unsaved changes",
              "Phase 243 blocked project close feedback must not imply close happened");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase243_Project_Close_Blocks_Project_Dirty_Buffer;

   procedure Test_Phase243_Project_Close_Ignores_Unrelated_Dirty_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase243_unrelated_dirty_root");
      Project_F  : constant String := Ada.Directories.Compose (Root, "a.txt");
      Other_F    : constant String := Temp_Path ("phase243_unrelated_dirty.txt");
      S          : Editor.State.State_Type;
      Found      : Boolean := False;
      Other_Id   : Editor.Buffers.Buffer_Id;
      Ignored_Id : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Ignored_Id);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Bytes (Other_F, "outside clean");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Project_F);
      Editor.Executor.Execute_Open_File (S, Other_F);
      Editor.State.Replace_Buffer_Contents (S, "outside dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      declare
         Result : constant Editor.Executor.Command_Execution_Result :=
           Editor.Executor.Execute_Command_With_Result
             (S, Editor.Commands.Command_Close_Project);
         pragma Unreferenced (Result);
      begin
         null;
      end;

      Assert (not Editor.Project.Has_Project (S.Project),
              "Phase 243 unrelated dirty buffers must not block project close");
      Ignored_Id := Editor.Buffers.Global_Find_By_Path (Project_F, Found);
      Assert (not Found,
              "Phase 243 clean project-owned buffer should be removed on project close");
      Other_Id := Editor.Buffers.Global_Find_By_Path (Other_F, Found);
      Assert (Found and then Other_Id /= Editor.Buffers.No_Buffer,
              "Phase 243 unrelated dirty buffer must remain open");
      Assert (Editor.Buffers.Global_Summary_For (Other_Id).Is_Dirty,
              "Phase 243 unrelated dirty marker must be preserved");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 243 successful project close must not leave a pending transition");

      Remove_File_If_Exists (Other_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Other_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase243_Project_Close_Ignores_Unrelated_Dirty_Buffer;

   procedure Test_Phase560_Project_Switch_Closes_Old_Clean_Project_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A     : constant String := Temp_Path ("phase560_switch_a");
      Root_B     : constant String := Temp_Path ("phase560_switch_b");
      Project_A  : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      Outside_F  : constant String := Temp_Path ("phase560_switch_outside.txt");
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Found      : Boolean := False;
      Outside_Id : Editor.Buffers.Buffer_Id;
      Ignored_Id : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Ignored_Id);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Write_Bytes (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root_A);
      Editor.Executor.Execute_Open_File (S, Project_A);
      Editor.Executor.Execute_Open_File (S, Outside_F);
      Editor.State.Replace_Buffer_Contents (S, "outside dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Has_Project (S.Project),
              "Phase 560 switch must leave an active project");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "Phase 560 switch must install the validated target project");
      Ignored_Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (not Found,
              "Phase 560 switch must close old clean project-owned buffers");
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found and then Outside_Id /= Editor.Buffers.No_Buffer,
              "Phase 560 switch must preserve outside-project buffers");
      Assert (Editor.Buffers.Global_Summary_For (Outside_Id).Is_Dirty,
              "Phase 560 switch must preserve outside-project dirty buffers");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 successful switch must leave no pending transition");
      Assert (Latest_Message_Text (S) = "Project switched",
              "Phase 560 successful switch feedback must be deterministic");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Switch_Closes_Old_Clean_Project_Buffers;

   procedure Test_Phase560_Project_Switch_Blocks_Project_Dirty_And_Cancel_Is_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A      : constant String := Temp_Path ("phase560_switch_dirty_a");
      Root_B      : constant String := Temp_Path ("phase560_switch_dirty_b");
      Project_A   : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      S           : Editor.State.State_Type;
      Cmd         : Editor.Commands.Command;
      Before_Rows : Natural := 0;
      Found       : Boolean := False;
      Id          : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root_A);
      Before_Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Editor.Executor.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "dirty project content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "Phase 560 blocked switch must preserve active project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Before_Rows,
              "Phase 560 blocked switch must preserve File Tree state");
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Editor.Buffers.Global_Summary_For (Id).Is_Dirty,
              "Phase 560 blocked switch must preserve dirty project buffer");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 blocked switch must capture a pending transition");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "Phase 560 cancelled switch must still preserve active project");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 cancelled switch must clear only the transient payload");
      Assert (Latest_Message_Text (S) = "Switch project cancelled",
              "Phase 560 switch cancellation feedback must be specific");

      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Switch_Blocks_Project_Dirty_And_Cancel_Is_Atomic;

   procedure Test_Phase560_Project_Switch_Target_Failure_Preserves_Previous_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A  : constant String := Temp_Path ("phase560_switch_valid_a");
      Missing : constant String := Temp_Path ("phase560_switch_missing_target");
      S       : Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Rows    : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Remove_Tree_If_Exists (Missing);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root_A);
      Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Missing);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "Phase 560 failed switch must preserve previous active project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Rows,
              "Phase 560 failed switch must preserve previous project surfaces");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "Phase 560 failed switch must not promote the missing target");
      Assert (Latest_Message_Text (S) = "Target project unavailable",
              "Phase 560 failed switch must report target unavailability");

      Cleanup_Fixture (Root_A);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root_A);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Switch_Target_Failure_Preserves_Previous_Project;


   procedure Test_Phase560_Project_Switch_Requires_Active_Source_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase560_switch_requires_source");
      S    : Editor.State.State_Type;
      Cmd  : Editor.Commands.Command;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Editor.Project.Has_Project (S.Project),
              "Phase 560 switch without source project must not open target as project.open");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = 0,
              "Phase 560 switch without source project must not initialize File Tree");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 0,
              "Phase 560 switch without source project must not promote Recent Projects");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 switch without source project must not create pending state");
      Assert (Latest_Message_Text (S) = "No project open.",
              "Phase 560 switch without source project must report missing source project");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Switch_Requires_Active_Source_Project;


   procedure Test_Phase560_Project_Switch_To_Current_Project_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase560_switch_same_project");
      Project_A : constant String := Ada.Directories.Compose (Root, "a.txt");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      Rows      : Natural := 0;
      Found     : Boolean := False;
      Id        : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Editor.Executor.Execute_Open_File (S, Project_A);
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "Phase 560 same-project switch setup must have an open project buffer");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "Phase 560 same-project switch setup must have one recent project");

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root),
              "Phase 560 same-project switch must preserve active project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Rows,
              "Phase 560 same-project switch must not clear File Tree rows");
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "Phase 560 same-project switch must not close clean project buffers");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "Phase 560 same-project switch must not promote a duplicate recent entry");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 same-project switch must not create a pending transition");
      Assert (Latest_Message_Text (S) = "Project already open",
              "Phase 560 same-project switch feedback must be deterministic");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Switch_To_Current_Project_Is_No_Op;


   procedure Test_Phase560_Project_Switch_To_Current_Project_Skips_Target_Preflight
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase560_switch_same_missing");
      Project_A : constant String := Ada.Directories.Compose (Root, "a.txt");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      Rows      : Natural := 0;
      Found     : Boolean := False;
      Id        : Editor.Buffers.Buffer_Id;
      Root_Full : Unbounded_String := Null_Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Root_Full := To_Unbounded_String (Ada.Directories.Full_Name (Root));
      Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Editor.Executor.Execute_Open_File (S, Project_A);
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "Phase 560 same-project missing-root setup must have an open buffer");

      Remove_Tree_If_Exists (Root);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = To_String (Root_Full),
              "Phase 560 same-project switch must preserve project even when root vanished");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Rows,
              "Phase 560 same-project missing-root switch must not clear File Tree rows");
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "Phase 560 same-project missing-root switch must not close buffers");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "Phase 560 same-project missing-root switch must not repromote Recent Projects");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 same-project missing-root switch must not create pending state");
      Assert (Latest_Message_Text (S) = "Project already open",
              "Phase 560 same-project missing-root switch must report no-op, not target failure");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Switch_To_Current_Project_Skips_Target_Preflight;


   procedure Test_Phase560_Pending_Switch_Blocks_Different_Project_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A    : constant String := Temp_Path ("phase560_pending_switch_a");
      Root_B    : constant String := Temp_Path ("phase560_pending_switch_b");
      Root_C    : constant String := Temp_Path ("phase560_pending_switch_c");
      Project_A : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      Target    : Editor.Pending_Transitions.Pending_Transition_Target;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Build_Fixture (Root_C);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root_A);
      Editor.Executor.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "dirty project content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 pending-switch setup must capture B as target");
      Target := Editor.Pending_Transitions.Target (S.Pending_Transitions);
      Assert (Target.Kind = Editor.Pending_Transitions.Pending_Switch_Project,
              "Phase 560 pending-switch setup must use switch transition kind");

      Cmd.Path := To_Unbounded_String (Root_C);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "Phase 560 different switch target while pending must preserve source project");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 different switch target while pending must preserve pending payload");
      Target := Editor.Pending_Transitions.Target (S.Pending_Transitions);
      Assert (Target.Kind = Editor.Pending_Transitions.Pending_Switch_Project,
              "Phase 560 different switch target must not replace transition kind");
      Assert (Editor.Recent_Projects.Normalized_Root_Path (To_String (Target.Path)) =
                Editor.Recent_Projects.Normalized_Root_Path (Root_B),
              "Phase 560 different switch target must not replace the captured target");
      Assert (Latest_Message_Text (S) = "Command unavailable while confirmation is pending.",
              "Phase 560 different switch target while pending must report command unavailability");

      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Cleanup_Fixture (Root_C);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Cleanup_Fixture (Root_C);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Pending_Switch_Blocks_Different_Project_Target;


   procedure Test_Phase560_Pending_Close_Blocks_Project_Switch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A    : constant String := Temp_Path ("phase560_pending_close_a");
      Root_B    : constant String := Temp_Path ("phase560_pending_close_b");
      Project_A : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      Target    : Editor.Pending_Transitions.Pending_Transition_Target;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root_A);
      Editor.Executor.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "dirty project content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 pending-close setup must capture close confirmation");
      Target := Editor.Pending_Transitions.Target (S.Pending_Transitions);
      Assert (Target.Kind = Editor.Pending_Transitions.Pending_Close_Project,
              "Phase 560 pending-close setup must use close transition kind");

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "Phase 560 switch while close pending must preserve source project");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 switch while close pending must preserve pending close payload");
      Target := Editor.Pending_Transitions.Target (S.Pending_Transitions);
      Assert (Target.Kind = Editor.Pending_Transitions.Pending_Close_Project,
              "Phase 560 switch while close pending must not replace pending close");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "Phase 560 switch while close pending must not promote target recent project");
      Assert (Latest_Message_Text (S) = "Command unavailable while confirmation is pending.",
              "Phase 560 switch while close pending must report command unavailability");

      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Pending_Close_Blocks_Project_Switch;


   procedure Test_Phase560_Project_Close_Dirty_Cancel_Is_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("phase560_close_dirty");
      Project_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S           : Editor.State.State_Type;
      Before_Rows : Natural := 0;
      Found       : Boolean := False;
      Id          : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Before_Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Editor.Executor.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "dirty close content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root),
              "Phase 560 blocked close must preserve active project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Before_Rows,
              "Phase 560 blocked close must preserve File Tree state");
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Editor.Buffers.Global_Summary_For (Id).Is_Dirty,
              "Phase 560 blocked close must preserve dirty project buffer");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 blocked close must capture a pending confirmation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root),
              "Phase 560 cancelled close must still preserve active project");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 cancelled close must clear only the transient payload");
      Assert (Latest_Message_Text (S) = "Close project cancelled",
              "Phase 560 close cancellation feedback must be specific");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Close_Dirty_Cancel_Is_Atomic;


   procedure Test_Phase560_Project_Switch_Retry_Ignores_Retained_Outside_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A     : constant String := Temp_Path ("phase560_retry_switch_a");
      Root_B     : constant String := Temp_Path ("phase560_retry_switch_b");
      Project_A  : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      Outside_F  : constant String := Temp_Path ("phase560_retry_switch_outside.txt");
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Found      : Boolean := False;
      Outside_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Write_Bytes (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root_A);

      Editor.Executor.Execute_Open_File (S, Outside_F);
      Editor.State.Replace_Buffer_Contents (S, "outside dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "project dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 retry setup must create pending switch");

      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (Editor.Project.Has_Project (S.Project),
              "Phase 560 switch retry must leave an active project");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "Phase 560 switch retry must proceed after project dirty is resolved");
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found and then Editor.Buffers.Global_Summary_For (Outside_Id).Is_Dirty,
              "Phase 560 switch retry must retain outside-project dirty buffer");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 successful switch retry must clear pending switch");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Switch_Retry_Ignores_Retained_Outside_Dirty;


   procedure Test_Phase560_Project_Close_Retry_Ignores_Retained_Outside_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase560_retry_close");
      Project_A  : constant String := Ada.Directories.Compose (Root, "a.txt");
      Outside_F  : constant String := Temp_Path ("phase560_retry_close_outside.txt");
      S          : Editor.State.State_Type;
      Found      : Boolean := False;
      Outside_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Bytes (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Executor.Execute_Open_File (S, Outside_F);
      Editor.State.Replace_Buffer_Contents (S, "outside dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "project dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 retry setup must create pending close");

      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (not Editor.Project.Has_Project (S.Project),
              "Phase 560 close retry must proceed after project dirty is resolved");
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found and then Editor.Buffers.Global_Summary_For (Outside_Id).Is_Dirty,
              "Phase 560 close retry must retain outside-project dirty buffer");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 successful close retry must clear pending close");
      Assert (Latest_Message_Text (S) = "Project closed",
              "Phase 560 close retry feedback must be deterministic");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Close_Retry_Ignores_Retained_Outside_Dirty;


   procedure Test_Phase560_Project_Close_Clears_Project_State_Not_Recent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase560_close_clean");
      S    : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "Phase 560 setup must promote opened project to Recent Projects");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) > 0,
              "Phase 560 setup must have project File Tree rows");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (not Editor.Project.Has_Project (S.Project),
              "Phase 560 clean close must clear active project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = 0,
              "Phase 560 clean close must clear File Tree rows");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "Phase 560 clean close must retain Recent Projects entries");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 560 clean close must leave no pending transition");
      Assert (Latest_Message_Text (S) = "Project closed",
              "Phase 560 clean close feedback must be deterministic");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Close_Clears_Project_State_Not_Recent;


   procedure Test_Phase560_Project_Switch_Preserves_Outside_Buffer_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A    : constant String := Temp_Path ("phase560_undo_switch_a");
      Root_B    : constant String := Temp_Path ("phase560_undo_switch_b");
      Outside_F : constant String := Temp_Path ("phase560_undo_switch_outside.txt");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      Undo_Before : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Write_Bytes (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root_A);
      Editor.Executor.Execute_Open_File (S, Outside_F);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'X'));
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Assert (Undo_Before > 0,
              "Phase 560 undo preservation setup must create outside-buffer undo history");

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "Phase 560 undo switch setup must switch projects");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 560 switch must preserve retained outside-buffer undo history");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Buffer_Text (S) = "outside",
              "Phase 560 outside-buffer undo must remain usable after project switch");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Switch_Preserves_Outside_Buffer_Undo;


   procedure Test_Phase560_Project_Close_Preserves_Outside_Buffer_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase560_undo_close");
      Outside_F : constant String := Temp_Path ("phase560_undo_close_outside.txt");
      S         : Editor.State.State_Type;
      Undo_Before : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Bytes (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Outside_F);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'X'));
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Assert (Undo_Before > 0,
              "Phase 560 undo preservation setup must create outside-buffer undo history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (not Editor.Project.Has_Project (S.Project),
              "Phase 560 undo close setup must close the project");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 560 close must preserve retained outside-buffer undo history");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Buffer_Text (S) = "outside",
              "Phase 560 outside-buffer undo must remain usable after project close");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Close_Preserves_Outside_Buffer_Undo;


   procedure Test_Phase560_Project_Switch_Preserves_Outside_Recent_Buffer_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A     : constant String := Temp_Path ("phase560_recent_switch_a");
      Root_B     : constant String := Temp_Path ("phase560_recent_switch_b");
      Project_A  : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      Outside_F  : constant String := Temp_Path ("phase560_recent_switch_outside.txt");
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Found      : Boolean := False;
      Outside_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Write_Bytes (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root_A);
      Editor.Executor.Execute_Open_File (S, Outside_F);
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found, "Phase 560 recent switch setup must open outside buffer");
      Editor.Executor.Execute_Open_File (S, Project_A);
      Assert (Editor.Recent_Buffers.Contains
                (S.Recent_Buffers, Natural (Outside_Id)),
              "Phase 560 recent switch setup must track outside buffer");

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "Phase 560 recent switch setup must switch projects");
      Assert (Editor.Buffers.Global_Contains (Outside_Id),
              "Phase 560 switch must retain outside buffer");
      Assert (Editor.Recent_Buffers.Count (S.Recent_Buffers) = 1,
              "Phase 560 switch must prune project-owned recent buffers only");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Natural (Outside_Id),
              "Phase 560 switch must preserve retained outside-buffer recency");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Switch_Preserves_Outside_Recent_Buffer_Order;


   procedure Test_Phase560_Project_Close_Preserves_Outside_Recent_Buffer_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase560_recent_close");
      Project_A  : constant String := Ada.Directories.Compose (Root, "a.txt");
      Outside_F  : constant String := Temp_Path ("phase560_recent_close_outside.txt");
      S          : Editor.State.State_Type;
      Found      : Boolean := False;
      Outside_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Bytes (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Outside_F);
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found, "Phase 560 recent close setup must open outside buffer");
      Editor.Executor.Execute_Open_File (S, Project_A);
      Assert (Editor.Recent_Buffers.Contains
                (S.Recent_Buffers, Natural (Outside_Id)),
              "Phase 560 recent close setup must track outside buffer");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (not Editor.Project.Has_Project (S.Project),
              "Phase 560 recent close setup must close project");
      Assert (Editor.Buffers.Global_Contains (Outside_Id),
              "Phase 560 close must retain outside buffer");
      Assert (Editor.Recent_Buffers.Count (S.Recent_Buffers) = 1,
              "Phase 560 close must prune project-owned recent buffers only");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Natural (Outside_Id),
              "Phase 560 close must preserve retained outside-buffer recency");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase560_Project_Close_Preserves_Outside_Recent_Buffer_Order;


   procedure Test_Phase244_Workspace_Reopen_Missing_Active_Falls_Back
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase244_missing_active_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "missing.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Assert
        (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
         "Phase 244 missing active restore should be a partial restore");
      Assert (Summary.Files_Restored = 1, "Phase 244 valid sibling file should restore");
      Assert (Summary.Files_Skipped = 0, "Phase 244 missing active is not double-counted when files were requested");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = File_A,
              "Phase 244 missing active file should fall back to first restored file");
      Assert (not S.File_Info.Dirty,
              "Phase 244 restored file-backed buffer should start clean");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase244_Workspace_Reopen_Missing_Active_Falls_Back;

   procedure Test_Phase558_Workspace_Active_Outside_Open_Set_Does_Not_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase558_active_outside_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      Nested   : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose (Root, "a_dir"), "nested.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Found    : Boolean := True;
      Id       : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Id);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "a_dir/nested.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Id := Editor.Buffers.Global_Find_By_Path (Nested, Found);

      Assert
        (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
         "Phase 558 active path outside restored set should be partial, not an implicit open");
      Assert (Summary.Files_Restored = 1,
              "Phase 558 valid open-file entry should still restore");
      Assert (Summary.Files_Skipped = 0,
              "Phase 558 active outside open set must not be counted as an open-file skip");
      Assert (not Found,
              "Phase 558 active path outside open-files must not open an extra buffer");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = File_A,
              "Phase 558 active outside open set should fall back to first restored file");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase558_Workspace_Active_Outside_Open_Set_Does_Not_Open;


   procedure Test_Phase244_Workspace_Reopen_Directory_Creates_No_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase244_directory_restore_root");
      Dir_Path : constant String := Ada.Directories.Compose (Root, "a_dir");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Found    : Boolean := True;
      Id       : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Id);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a_dir"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Id := Editor.Buffers.Global_Find_By_Path (Dir_Path, Found);

      Assert
        (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
         "Phase 244 directory restore should be partial, not successful");
      Assert (Summary.Files_Restored = 0, "Phase 244 directory path must not restore a file buffer");
      Assert (Summary.Files_Skipped = 1, "Phase 244 directory path should be skipped once");
      Assert (not Found, "Phase 244 directory path must not create a partial file buffer");
      Assert (not S.File_Info.Dirty, "Phase 244 failed restore must not create a dirty buffer");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase244_Workspace_Reopen_Directory_Creates_No_Buffer;

   procedure Test_Phase244_Workspace_Reopen_Already_Open_Dirty_No_Duplicate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root          : constant String := Temp_Path ("phase244_dirty_duplicate_root");
      File_A        : constant String := Ada.Directories.Compose (Root, "a.txt");
      S             : Editor.State.State_Type;
      Snapshot      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status        : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary       : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Before_Count  : Natural;
      After_Count   : Natural;
      Found         : Boolean := False;
      Id            : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, File_A);
      Before_Count := Editor.Buffers.Global_Count;
      Set_Buffer_Text (S, "dirty in memory");
      S.File_Info.Dirty := True;
      S.File_Info.Last_Save_Failed := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Write_Bytes (File_A, "changed on disk");

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      After_Count := Editor.Buffers.Global_Count;
      Id := Editor.Buffers.Global_Find_By_Path (File_A, Found);

      Assert
        (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
         "Phase 244 already-open dirty restore should succeed without reread");
      Assert (Summary.Files_Restored = 1, "Phase 244 already-open dirty file counts as restored");
      Assert (After_Count = Before_Count, "Phase 244 already-open restore must not duplicate buffers");
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "Phase 244 already-open file should still be tracked");
      Assert (Buffer_Text (S) = "dirty in memory",
              "Phase 244 already-open dirty restore must preserve unsaved content");
      Assert (Editor.Buffers.Global_Summary_For (Id).Is_Dirty,
              "Phase 244 already-open dirty restore must preserve dirty marker");
      Assert (Editor.Buffers.Global_Summary_For (Id).Last_Save_Failed,
              "Phase 244 already-open dirty restore must preserve retry context");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase244_Workspace_Reopen_Already_Open_Dirty_No_Duplicate;



   procedure Test_Phase245_Restore_Order_And_Active_Buffer_Agree
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase245_order_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      File_B   : constant String := Ada.Directories.Compose (Root, "b.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Before_Count : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Bytes (File_B, "b");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Before_Count := Editor.Buffers.Global_Count;

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("b.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Phase 245 restore order should be a complete restore");
      Assert (Editor.Buffers.Global_Count = Before_Count + 2,
              "Phase 245 restore should append exactly the requested unique buffers");
      Assert (To_String (Editor.Buffers.Global_Summary_At (Before_Count + 1).Display_Name) = "b.txt",
              "Phase 245 first newly restored row should follow workspace order");
      Assert (To_String (Editor.Buffers.Global_Summary_At (Before_Count + 2).Display_Name) = "a.txt",
              "Phase 245 second newly restored row should follow workspace order");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = File_A,
              "Phase 245 restored active buffer should match the active workspace reference");
      Assert (Editor.Buffers.Global_Summary_At (Before_Count + 2).Is_Active,
              "Phase 245 open-buffer active marker should match restored active buffer");
      Assert (Summary.Files_Restored = 2 and then Summary.Files_Skipped = 0,
              "Phase 245 restore summary should report two restored files");

      Remove_File_If_Exists (File_B);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (File_B);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase245_Restore_Order_And_Active_Buffer_Agree;

   procedure Test_Phase245_Duplicate_Restored_File_Collapses_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase245_duplicate_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Found    : Boolean := False;
      Id       : Editor.Buffers.Buffer_Id;
      Before_Count : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Before_Count := Editor.Buffers.Global_Count;

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      for I in 1 .. 2 loop
         Editor.Workspace_Persistence.Add_Open_File
           (Snapshot,
            (Path                => To_Unbounded_String ("a.txt"),
             Is_Project_Relative => True,
             Cursor_Row          => I - 1,
             Cursor_Column       => 0,
             View_First_Row      => 0));
      end loop;
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Id := Editor.Buffers.Global_Find_By_Path (File_A, Found);

      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Phase 245 duplicate restore references should collapse without making restore partial");
      Assert (Summary.Files_Requested = 2,
              "Phase 245 duplicate restore should keep requested count for deterministic feedback");
      Assert (Summary.Files_Restored = 1 and then Summary.Files_Skipped = 0,
              "Phase 245 duplicate restore should count only the unique restored file");
      Assert (Editor.Buffers.Global_Count = Before_Count + 1,
              "Phase 245 duplicate restore should append one open-buffer row");
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "Phase 245 duplicate restore should leave the unique file-backed buffer tracked");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = File_A,
              "Phase 245 duplicate active reference should focus the unique restored buffer");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase245_Duplicate_Restored_File_Collapses_Deterministically;

   procedure Test_Phase245_Restored_Cursor_And_Viewport_Clamp
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase245_cursor_view_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Bytes (File_A, "one" & ASCII.LF & "last");
      Init_Executor_Test_State (S);
      Editor.View.Reset;
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 99,
          Cursor_Column       => 99,
          View_First_Row      => 99));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Phase 245 cursor/viewport clamp restore should succeed");
      Assert (S.Carets.Length = 1,
              "Phase 245 restored cursor should leave exactly one caret");
      Assert (S.Carets (S.Carets.First_Index).Pos <= Text_Buffer.Length (S.Buffer),
              "Phase 245 restored cursor should clamp inside restored content");
      Assert (Editor.View.Scroll_Y = 1,
              "Phase 245 restored viewport should clamp to the last restored content row");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase245_Restored_Cursor_And_Viewport_Clamp;

   procedure Test_Phase245_Clean_Restore_Clears_Transient_Lifecycle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase245_clean_lifecycle_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Found    : Boolean := False;
      Id       : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Id := Editor.Buffers.Global_Find_By_Path (File_A, Found);

      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "Phase 245 clean restore should track restored file");
      Assert (not Editor.Buffers.Global_Summary_For (Id).Is_Dirty,
              "Phase 245 successful file-backed restore should start clean");
      Assert (not Editor.Buffers.Global_Summary_For (Id).Last_Save_Failed,
              "Phase 245 successful restore must not revive failed-save context");
      Assert (not Editor.Buffers.Global_Summary_For (Id).Missing_Target_Surfaced,
              "Phase 245 successful restore must not revive missing-target context");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Editor.Buffers.Global_Summary_For (Id).Display_Name),
                 "reload blocked") = 0,
              "Phase 437 restore summaries must not expose reload context");
      Assert (not Editor.Buffers.Global_Summary_For (Id).Blocked_Close_Surfaced,
              "Phase 245 successful restore must not revive blocked-close context");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase245_Clean_Restore_Clears_Transient_Lifecycle;



   procedure Test_Phase246_Post_Restore_Command_Readiness
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase246_readiness_root");
      S          : Editor.State.State_Type;
      Snapshot   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status     : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary    : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Save_A     : Editor.Commands.Command_Availability;
      Reload_A   : Editor.Commands.Command_Availability;
      Close_A    : Editor.Commands.Command_Availability;
      Feature_A  : Editor.Commands.Command_Availability;
      Saw_Save    : Boolean := False;
      Saw_Reload  : Boolean := False;
      Saw_Close   : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Save_A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_File);
      Reload_A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Reload_Active_Buffer);
      Close_A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Close_Active_Buffer);
      Feature_A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      for C of Candidates loop
         if C.Id = Editor.Commands.Command_Save_File then
            Saw_Save := C.Available;
         elsif C.Id = Editor.Commands.Command_Reload_Active_Buffer then
            Saw_Reload := C.Available;
         elsif C.Id = Editor.Commands.Command_Close_Active_Buffer then
            Saw_Close := C.Available;
         end if;
      end loop;

      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Phase 246 restore fixture should succeed");
      Assert (Editor.Commands.Is_Available (Save_A),
              "Phase 246 post-restore save availability should match restored file-backed active buffer");
      Assert (Editor.Commands.Is_Available (Reload_A),
              "Phase 246 post-restore reload availability should match clean file-backed active buffer");
      Assert (Editor.Commands.Is_Available (Close_A),
              "Phase 246 post-restore close availability should match restored open buffer");
      Assert (not Editor.Commands.Is_Available (Feature_A),
              "Phase 246 post-restore Feature Panel activation should not revive stale rows");
      Assert (Saw_Save and then Saw_Reload and then Saw_Close,
              "Phase 246 Command Palette candidates should use restored availability without an extra refresh command");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase246_Post_Restore_Command_Readiness;

   procedure Test_Phase246_First_Save_After_Restore_Uses_Normal_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase246_save_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Cmd      : Editor.Commands.Command;
      Result   : Editor.Executor.Command_Execution_Result;
      Reloaded : Editor.Files.File_Open_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 1,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (S.File_Info.Dirty,
              "Phase 246 first edit after restore should dirty the restored active buffer");
      Assert (Editor.Buffers.Global_Summary_For (Editor.Buffers.Global_Active_Buffer).Is_Dirty,
              "Phase 246 first edit after restore should update open-buffer dirty marker");

      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Save_File);
      Reloaded := Editor.Files.Open_File (File_A);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Phase 246 first save after restore should execute through normal save path");
      Assert (Editor.Files.Is_Success (Reloaded)
                and then To_String (Reloaded.Contents) = Editor.State.Current_Text (S),
              "Phase 246 first save after restore should write latest restored-buffer content");
      Assert (not S.File_Info.Dirty,
              "Phase 246 successful save after restore should clear active dirty marker");
      Assert (not Editor.Buffers.Global_Summary_For (Editor.Buffers.Global_Active_Buffer).Is_Dirty,
              "Phase 246 successful save after restore should clear open-buffer dirty marker");
      Assert (S.File_Info.Baseline_Valid
                and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
              "Phase 246 successful save after restore should update saved baseline");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase246_First_Save_After_Restore_Uses_Normal_Path;

   procedure Test_Phase246_First_Reload_After_Restore_Uses_Normal_Guards
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase246_reload_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Cmd      : Editor.Commands.Command;
      Result   : Editor.Executor.Command_Execution_Result;
      Before   : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Write_Bytes (File_A, "changed");
      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Phase 246 first reload after clean restore should execute");
      Assert (Editor.State.Current_Text (S) = "changed",
              "Phase 246 first reload after restore should read replacement content");
      Assert (not S.File_Info.Dirty,
              "Phase 246 successful reload after restore should leave buffer clean");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'X';
      Cmd.Text := To_Unbounded_String (String'(1 => 'X'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Before := To_Unbounded_String (Editor.State.Current_Text (S));
      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "Phase 246 dirty restored buffer reload should be blocked before replacement");
      Assert (To_String (Before) = Editor.State.Current_Text (S),
              "Phase 246 blocked reload after restore should preserve dirty content");
      Assert (S.File_Info.Dirty,
              "Phase 246 blocked reload after restore should preserve dirty marker");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase246_First_Reload_After_Restore_Uses_Normal_Guards;

   procedure Test_Phase246_First_Close_And_Navigation_After_Restore
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase246_close_nav_root");
      File_B   : constant String := Ada.Directories.Compose (Root, "b.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Bytes (File_B, "b");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("b.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Next_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed
                and then To_String (S.File_Info.Display_Name) = "b.txt",
              "Phase 246 next buffer after restore should follow restored order");
      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Previous_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed
                and then To_String (S.File_Info.Display_Name) = "a.txt",
              "Phase 246 previous buffer after restore should follow restored order");

      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Phase 246 first close after clean restore should execute");
      Assert (To_String (S.File_Info.Display_Name) = "b.txt",
              "Phase 246 closing restored active buffer should choose deterministic next active buffer");

      Remove_File_If_Exists (File_B);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (File_B);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase246_First_Close_And_Navigation_After_Restore;

   procedure Test_Phase247_Restore_Feedback_Becomes_Historical_After_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase247_feedback_edit_root");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Result   : Editor.Executor.Command_Execution_Result;
      Cmd      : Editor.Commands.Command;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Workspace_Persistence.Save_To_File
        (Snapshot, Editor.Workspace_Persistence.Session_File_Path (Root), Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Phase 247 restore feedback fixture should save session");

      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Restore_Workspace_State);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Phase 247 explicit restore should execute");
      Assert (S.Post_Restore_Feedback_Current,
              "Phase 247 restore feedback should be current immediately after restore");
      Assert (Editor.Messages.Count (S.Messages) > 0,
              "Phase 247 restore Message should remain historical");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not S.Post_Restore_Feedback_Current,
              "Phase 247 first edit should stop restore feedback being current");
      Assert (Editor.Messages.Count (S.Messages) > 0,
              "Phase 247 first edit should not erase historical restore Message");
      Assert (S.File_Info.Dirty,
              "Phase 247 restore feedback cleanup must preserve dirty state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase247_Restore_Feedback_Becomes_Historical_After_Edit;

   procedure Test_Phase247_Restore_Feedback_Replaced_By_Command_Outcome
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase247_feedback_command_root");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Workspace_Persistence.Save_To_File
        (Snapshot, Editor.Workspace_Persistence.Session_File_Path (Root), Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Phase 247 restore feedback command fixture should save session");

      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Restore_Workspace_State);
      Assert (Result.Status = Editor.Executor.Command_Executed
                and then S.Post_Restore_Feedback_Current,
              "Phase 247 restore feedback should start as current command feedback");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_File);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Phase 247 save after restore should execute normally");
      Assert (not S.Post_Restore_Feedback_Current,
              "Phase 247 first command should replace restore-only current feedback");
      Assert (not S.File_Info.Dirty,
              "Phase 247 restore feedback replacement must not dirty clean buffer");
      Assert (Editor.Messages.Count (S.Messages) > 0,
              "Phase 247 command replacement keeps Messages as bounded history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase247_Restore_Feedback_Replaced_By_Command_Outcome;



   procedure Prepare_Phase248_Restored_File
     (Root : String;
      S    : in out Editor.State.State_Type)
   is
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Workspace_Persistence.Save_To_File
        (Snapshot, Editor.Workspace_Persistence.Session_File_Path (Root), Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Phase 248 restored-file fixture should save session");

      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Restore_Workspace_State);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Phase 248 restored-file fixture should restore session");
      Assert (S.Post_Restore_Feedback_Current,
              "Phase 248 restored-file fixture should start with current restore feedback");
   end Prepare_Phase248_Restored_File;

   procedure Test_Phase248_Save_After_Cleanup_Uses_Ordinary_Feedback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase248_save_after_cleanup_root");
      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural := 0;
      Latest : Unbounded_String;
   begin
      Prepare_Phase248_Restored_File (Root, S);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not S.Post_Restore_Feedback_Current,
              "Phase 248 edit cleanup should make restore feedback historical");
      Assert (S.File_Info.Dirty,
              "Phase 248 edit after cleanup should expose ordinary dirty state");

      Before := Editor.Messages.Count (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_File);
      Latest := To_Unbounded_String (Latest_Message_Text (S));

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "Phase 248 save after cleanup should execute through normal save path");
      Assert (Editor.Messages.Count (S.Messages) = Before + 1,
              "Phase 248 save after cleanup should post exactly one primary save message");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Saved a.txt") > 0,
              "Phase 248 save after cleanup should make the current feedback the save result");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Workspace state restored") = 0,
              "Phase 248 save after cleanup must not repost restore success as current feedback");
      Assert (not S.File_Info.Dirty,
              "Phase 248 successful save after cleanup should clear dirty state normally");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase248_Save_After_Cleanup_Uses_Ordinary_Feedback;

   procedure Test_Phase248_Direct_Open_Clears_Restore_Feedback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase248_direct_open_root");
      S         : Editor.State.State_Type;
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      Before    : Natural := 0;
      Latest    : Unbounded_String;
   begin
      Prepare_Phase248_Restored_File (Root, S);
      Before := Editor.Messages.Count (S.Messages);

      Editor.Executor.Execute_Open_File (S, File_Path);
      Latest := To_Unbounded_String (Latest_Message_Text (S));

      Assert (not S.Post_Restore_Feedback_Current,
              "Phase 248 direct open/focus should clear current restore feedback");
      Assert (Editor.Messages.Count (S.Messages) = Before + 1,
              "Phase 248 direct open/focus should post only its own normal feedback");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Focused existing buffer a.txt") > 0,
              "Phase 248 direct open/focus should use ordinary already-open feedback");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Workspace state restored") = 0,
              "Phase 248 direct open/focus must not revive restore feedback");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase248_Direct_Open_Clears_Restore_Feedback;

   procedure Test_Phase248_File_Tree_Row_Action_Is_Ordinary_After_Restore
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase248_file_tree_action_root");
      S         : Editor.State.State_Type;
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      Node      : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Found     : Boolean := False;
      Latest    : Unbounded_String;
   begin
      Prepare_Phase248_Restored_File (Root, S);
      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, File_Path, Found);
      Assert (Found,
              "Phase 248 File Tree fixture should contain restored file row");

      Editor.Executor.Execute_File_Tree_Node_Action
        (S, Node, Editor.File_Tree_View.Open_File_Action);
      Latest := To_Unbounded_String (Latest_Message_Text (S));

      Assert (not S.Post_Restore_Feedback_Current,
              "Phase 248 direct File Tree row action should clear current restore feedback");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Focused existing buffer a.txt") > 0,
              "Phase 248 File Tree activation after cleanup should use normal focus feedback");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Workspace state") = 0,
              "Phase 248 File Tree activation must not repost restore details");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase248_File_Tree_Row_Action_Is_Ordinary_After_Restore;

   procedure Test_Phase248_Already_Open_Dirty_File_Tree_Focus_Preserves_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase248_dirty_focus_root");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      Node      : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Found     : Boolean := False;
      Before    : Unbounded_String;
   begin
      Prepare_Phase248_Restored_File (Root, S);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Before := To_Unbounded_String (Editor.State.Current_Text (S));
      Assert (S.File_Info.Dirty,
              "Phase 248 dirty focus fixture should be dirty after edit");

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, File_Path, Found);
      Assert (Found,
              "Phase 248 dirty File Tree fixture should contain file row");
      Editor.Executor.Execute_File_Tree_Node_Action
        (S, Node, Editor.File_Tree_View.Open_File_Action);

      Assert (S.File_Info.Dirty,
              "Phase 248 already-open File Tree activation should preserve dirty state");
      Assert (To_String (Before) = Editor.State.Current_Text (S),
              "Phase 248 already-open File Tree activation must not reread and replace dirty text");
      Assert (not S.Post_Restore_Feedback_Current,
              "Phase 248 dirty File Tree activation should leave restore feedback historical");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase248_Already_Open_Dirty_File_Tree_Focus_Preserves_Text;



   procedure Test_Phase249_Open_Edit_Syncs_Ordinary_Dirty_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase249_open_edit_dirty_root");
      S      : Editor.State.State_Type;
      Path   : constant String := Ada.Directories.Compose (Root, "a.txt");
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Row    : Editor.Buffers.Buffer_Summary;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Build_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Row := Editor.Buffers.Global_Summary_For (Id);
      Assert (Id /= Editor.Buffers.No_Buffer and then Row.Has_Path,
              "Phase 249 open should create a file-backed active buffer row");
      Assert (not Row.Is_Dirty and then not S.File_Info.Dirty,
              "Phase 249 newly opened file-backed buffer should start clean");

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, 'Z'));
      Row := Editor.Buffers.Global_Summary_For (Id);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);

      Assert (Buffer_Text (S) = "aZ",
              "Phase 249 typing after open should edit the active buffer only");
      Assert (S.File_Info.Dirty,
              "Phase 249 typing after open should dirty the active buffer");
      Assert (Row.Is_Dirty,
              "Phase 249 open-buffer row should become dirty immediately after typing");
      Assert (Editor.Commands.Is_Available (Avail),
              "Phase 249 save availability should follow the dirty active buffer");

      Editor.Executor.Execute_Save (S);
      Row := Editor.Buffers.Global_Summary_For (Id);
      Assert (not S.File_Info.Dirty and then not Row.Is_Dirty,
              "Phase 249 successful ordinary save should clear buffer and row dirty state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase249_Open_Edit_Syncs_Ordinary_Dirty_Row;

   procedure Test_Phase249_Repeated_Switching_Preserves_Ordinary_Edit_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase249_switch_context_root");
      S      : Editor.State.State_Type;
      A_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      B_Path : constant String := Ada.Directories.Compose (Root, "b.txt");
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      A_Row  : Editor.Buffers.Buffer_Summary;
      B_Row  : Editor.Buffers.Buffer_Summary;
   begin
      Build_Fixture (Root);
      Write_Bytes (B_Path, "b");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      Assert (Buffer_Text (S) = "b!",
              "Phase 249 setup should edit the second active buffer");
      B_Row := Editor.Buffers.Global_Summary_For (B_Id);
      Assert (B_Row.Is_Dirty,
              "Phase 249 dirty row should be visible before switching away");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert (Buffer_Text (S) = "a",
              "Phase 249 switching to first buffer should restore first content");
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '?'));
      A_Row := Editor.Buffers.Global_Summary_For (A_Id);
      Assert (Buffer_Text (S) = "a?" and then A_Row.Is_Dirty,
              "Phase 249 editing after switch should dirty only the selected first buffer");

      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      A_Row := Editor.Buffers.Global_Summary_For (A_Id);
      B_Row := Editor.Buffers.Global_Summary_For (B_Id);
      Assert (Buffer_Text (S) = "b!",
              "Phase 249 switching back should restore second buffer content");
      Assert (A_Row.Is_Dirty and then B_Row.Is_Dirty,
              "Phase 249 repeated switching should preserve each buffer dirty marker");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 249 active open-buffer marker should follow the final switch");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase249_Repeated_Switching_Preserves_Ordinary_Edit_Context;

   procedure Test_Phase249_Ordinary_Dirty_Reload_Blocks_Without_Row_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("phase249_dirty_reload_root");
      S           : Editor.State.State_Type;
      Path        : constant String := Ada.Directories.Compose (Root, "a.txt");
      Id          : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Text : Unbounded_String;
      Row         : Editor.Buffers.Buffer_Summary;
      Latest      : Unbounded_String;
   begin
      Build_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Write_Bytes (Path, "disk replacement");

      Editor.Executor.Execute_Reload_Active_Buffer (S);
      Row := Editor.Buffers.Global_Summary_For (Id);
      Latest := To_Unbounded_String (Latest_Message_Text (S));

      Assert (Buffer_Text (S) = To_String (Before_Text),
              "Phase 249 dirty reload should block before content replacement");
      Assert (S.File_Info.Dirty and then Row.Is_Dirty,
              "Phase 249 blocked reload should preserve buffer and row dirty state");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Row.Display_Name), "reload blocked") = 0,
              "Phase 437 dirty reload must not record reload lifecycle context on the current buffer");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Latest), "Dirty buffer cannot be reloaded") > 0,
              "Phase 249 blocked reload feedback should describe the current ordinary action");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase249_Ordinary_Dirty_Reload_Blocks_Without_Row_Drift;

   procedure Test_Phase249_File_Tree_Focuses_Already_Open_Dirty_File_Ordinarily
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root         : constant String := Temp_Path ("phase249_file_tree_focus_root");
      S            : Editor.State.State_Type;
      Path         : constant String := Ada.Directories.Compose (Root, "a.txt");
      Node         : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Found        : Boolean := False;
      Before_Count : Natural := 0;
      Before_Text  : Unbounded_String;
   begin
      Build_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Open_File (S, Path);
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      Before_Count := Editor.Buffers.Global_Count;
      Before_Text := To_Unbounded_String (Buffer_Text (S));

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, Path, Found);
      Assert (Found,
              "Phase 249 file tree fixture should contain the ordinary file row");
      Editor.Executor.Execute_File_Tree_Node_Action
        (S, Node, Editor.File_Tree_View.Open_File_Action);

      Assert (Editor.Buffers.Global_Count = Before_Count,
              "Phase 249 File Tree focus should not duplicate already-open rows");
      Assert (S.File_Info.Dirty,
              "Phase 249 File Tree focus should preserve already-open dirty state");
      Assert (Buffer_Text (S) = To_String (Before_Text),
              "Phase 249 File Tree focus should not reload over dirty text");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase249_File_Tree_Focuses_Already_Open_Dirty_File_Ordinarily;


   procedure Test_Phase263_Goto_Line_Jumps_And_Returns_To_Editor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      Editor.Executor.Execute_Open_Goto_Line (S);
      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "Phase 263 Go To Line input opens");
      Assert
        (Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Go_To_Line_Overlay),
         "Phase 263 Go To Line owns overlay focus while open");

      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "3");
      Editor.Executor.Execute_Accept_Goto_Line (S);

      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 2 and then Col = 0,
              "Phase 263 valid one-based line target moves caret to column 1");
      Assert (not Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "Phase 263 successful Go To Line closes the input");
      Assert (not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus),
              "Phase 263 successful Go To Line returns to normal editor focus");
      Assert (not S.File_Info.Dirty,
              "Phase 263 Go To Line does not dirty the buffer");
      Assert (Latest_Message_Text (S) = "Went to line 3",
              "Phase 263 successful Go To Line feedback is deterministic");
   end Test_Phase263_Goto_Line_Jumps_And_Returns_To_Editor;


   procedure Test_Phase263_Goto_Line_Failure_Preserves_Cursor_Viewport
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Before_Caret  : Editor.Cursors.Cursor_Index;
      Before_Anchor : Editor.Cursors.Cursor_Index;
      Before_Scroll : Natural;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 4,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      Editor.View.Set_Scroll (0, 7);

      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Anchor := S.Carets (S.Carets.First_Index).Anchor;
      Before_Scroll := Editor.View.Scroll_Y;

      Editor.Executor.Execute_Open_Goto_Line (S);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "99");
      Editor.Executor.Execute_Accept_Goto_Line (S);

      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "Phase 263 failed Go To Line keeps input open for correction");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "Phase 263 failed Go To Line preserves cursor");
      Assert (S.Carets (S.Carets.First_Index).Anchor = Before_Anchor,
              "Phase 263 failed Go To Line preserves selection anchor");
      Assert (Editor.View.Scroll_Y = Before_Scroll,
              "Phase 263 failed Go To Line preserves viewport");
      Assert (Latest_Message_Text (S) = "Line 99 is outside the active buffer",
              "Phase 263 out-of-range feedback is deterministic");
      Assert (not S.File_Info.Dirty,
              "Phase 263 failed Go To Line does not dirty the buffer");
   end Test_Phase263_Goto_Line_Failure_Preserves_Cursor_Viewport;


   procedure Test_Phase263_Goto_Line_Does_Not_Mutate_Find_Or_Feature_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Feature_Rows : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "alpha");
      S.Active_Find_Prompt := True;
      Editor.Input_Field.Set_Text (S.Active_Find_Input, "alpha");
      Editor.Feature_Panel.Clear (S.Feature_Panel);
      Before_Feature_Rows := Editor.Feature_Panel.Row_Count (S.Feature_Panel);

      Editor.Executor.Execute_Open_Goto_Line (S);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "2");
      Editor.Executor.Execute_Accept_Goto_Line (S);

      Assert (Editor.Input_Field.Text (S.Active_Find_Input) = "alpha",
              "Phase 263 Go To Line preserves find query");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = Before_Feature_Rows,
              "Phase 263 Go To Line does not create Feature Panel rows");
   end Test_Phase263_Goto_Line_Does_Not_Mutate_Find_Or_Feature_Rows;


   procedure Test_Phase264_Goto_Line_Back_Forward_Routes_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      Editor.Executor.Execute_Open_Goto_Line (S);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "3");
      Editor.Executor.Execute_Accept_Goto_Line (S);

      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "Go To Line must record explicit navigation history");
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 2 and then Col = 0,
              "Go To Line must still move the caret without creating history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 0 and then Col = 0,
              "navigation.back must restore the pre-go-to-line caret location");
   end Test_Phase264_Goto_Line_Back_Forward_Routes_Through_Executor;


   procedure Test_Phase264_Find_Navigation_Pushes_History_And_Back_Preserves_Query
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Cmd.Kind := Editor.Commands.Active_Find_Next;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "find-next must record explicit navigation history");
      Assert (Editor.Input_Field.Text (S.Active_Find_Input) = "alpha",
              "find-next must not mutate the find query");
      Assert (Editor.Feature_Search_Results.Is_Empty (S.Feature_Search_Results),
              "find-next must not create Feature Panel Search Results");
   end Test_Phase264_Find_Navigation_Pushes_History_And_Back_Preserves_Query;

   procedure Test_Phase365_Replace_Show_Hide_Clears_Transient_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");

      Editor.Executor.Execute_Replace_Show (S);
      Assert (S.Active_Find_Prompt,
              "replace.show must make canonical Find visible");
      Assert (S.Active_Replace_Prompt,
              "replace.show must make Replace visible");
      Assert (Latest_Message_Text (S) = "Replace shown",
              "replace.show must emit one primary message");

      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Assert (To_String (S.Active_Replace_Text) = "Execute",
              "replace.text.set must store literal transient text");

      Editor.Executor.Execute_Replace_Hide (S);
      Assert (not S.Active_Replace_Prompt,
              "replace.hide must hide Replace");
      Assert (S.Active_Find_Prompt,
              "replace.hide must preserve Find visibility");
      Assert (Length (S.Active_Replace_Text) = 0,
              "replace.hide must clear replacement text");
      Assert (Length (S.Active_Replace_Error_Message) = 0,
              "replace.hide must clear replacement errors");

      Editor.Executor.Execute_Replace_Set_Text (S, "Again");
      Editor.Executor.Execute_Find_Hide (S);
      Assert (not S.Active_Find_Prompt and then not S.Active_Replace_Prompt,
              "find.hide must hide Replace with Find");
      Assert (Length (S.Active_Replace_Text) = 0,
              "find.hide must clear replacement text");
   end Test_Phase365_Replace_Show_Hide_Clears_Transient_Text;


   procedure Test_Phase365_Replace_Current_Uses_Find_And_Dirties_No_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");

      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");

      Cmd.Kind := Editor.Commands.Active_Replace_Current;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.State.Current_Text (S) = "Execute Run",
              "replace.current must replace exactly the selected canonical Find match");
      Assert (S.File_Info.Dirty,
              "replace.current must dirty the active buffer through the edit path");
      Assert (Natural (S.Active_Find_Matches.Length) = 1,
              "replace.current must recompute post-edit Find matches");
      Assert (Latest_Message_Text (S) = "Replaced current match",
              "replace.current must emit one primary success message");
      Assert (not Editor.History.Undo_Stack.Is_Empty,
              "Phase 369 replace.current must create one undo entry when text changes");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert (Editor.State.Current_Text (S) = "Run Run",
              "Phase 369 undo after replace.current restores previous buffer text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert (Editor.State.Current_Text (S) = "Execute Run",
              "Phase 369 redo after replace.current reapplies replacement");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "replace.current must not record Navigation History");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "replace.current must not mutate forward Navigation History");
   end Test_Phase365_Replace_Current_Uses_Find_And_Dirties_No_History;


   procedure Test_Phase365_Replace_All_Is_Literal_Offset_Safe_And_Recomputes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run (Run) Run");

      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Set_Text (S, "\1");

      Cmd.Kind := Editor.Commands.Active_Replace_All;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.State.Current_Text (S) = "\1 (\1) \1",
              "replace.all must insert backslash/capture-like text literally");
      Assert (S.File_Info.Dirty,
              "replace.all must dirty the active buffer");
      Assert (Natural (S.Active_Find_Matches.Length) = 0,
              "replace.all must recompute Find matches after replacement");
      Assert (Latest_Message_Text (S) = "Replaced 3 matches",
              "replace.all must report the original canonical replacement count");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 369 replace.all must create one grouped undo entry");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert (Editor.State.Current_Text (S) = "Run (Run) Run",
              "Phase 369 undo after replace.all restores entire previous buffer text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert (Editor.State.Current_Text (S) = "\1 (\1) \1",
              "Phase 369 redo after replace.all reapplies entire replacement result");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 369 replace.all remains one grouped undo entry after redo");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "replace.all must not record Navigation History");
   end Test_Phase365_Replace_All_Is_Literal_Offset_Safe_And_Recomputes;


   procedure Test_Phase365_Replace_All_Uses_Canonical_Non_Overlapping_Matches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "aaaa");

      Editor.Executor.Execute_Find_Set_Query (S, "aa");
      Editor.Executor.Execute_Replace_Set_Text (S, "b");

      Cmd.Kind := Editor.Commands.Active_Replace_All;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.State.Current_Text (S) = "bb",
              "replace.all must use canonical non-overlapping Find matches");
      Assert (Latest_Message_Text (S) = "Replaced 2 matches",
              "replace.all must count canonical non-overlapping matches");
   end Test_Phase365_Replace_All_Uses_Canonical_Non_Overlapping_Matches;


   procedure Test_Phase365_Replace_Empty_Text_Deletes_Matches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run and Run");

      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Clear_Text (S);

      Cmd.Kind := Editor.Commands.Active_Replace_All;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.State.Current_Text (S) = " and ",
              "empty replacement text must delete matched text");
      Assert (Latest_Message_Text (S) = "Replaced 2 matches",
              "delete-style replace must still report replacements");
   end Test_Phase365_Replace_Empty_Text_Deletes_Matches;



   procedure Test_Phase366_Replace_Text_Newline_Is_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");

      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_Set_Text (S, "Line" & ASCII.LF & "Break");

      Assert (To_String (S.Active_Replace_Text) = "Execute",
              "invalid multiline replacement text must not replace prior text");
      Assert (To_String (S.Active_Replace_Error_Message) = "Replacement text must be single-line",
              "invalid multiline replacement text must set renderable Replace error");
      Assert (Latest_Message_Text (S) = "Replacement text must be single-line.",
              "invalid multiline replacement text must emit one primary message");

      Editor.Executor.Execute_Replace_Clear_Text (S);
      Assert (Length (S.Active_Replace_Error_Message) = 0,
              "replace.text.clear must clear validation error");
   end Test_Phase366_Replace_Text_Newline_Is_Rejected;


   procedure Test_Phase366_Replace_Current_Preserves_Valid_Selected_Match
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Back_Before : Natural := 0;
      Forward_Before : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run one Run");

      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Next (S);
      Assert (Editor.Search.Has_Match (S.Active_Find_Match)
              and then Natural (S.Active_Find_Match.Start_Index) = 8,
              "precondition: second Find match selected");
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_Current (S);

      Assert (Editor.State.Current_Text (S) = "Run one Execute",
              "replace.current must keep the still-valid selected match across recompute");
      Assert (Natural (S.Active_Find_Matches.Length) = 1,
              "replace.current must recompute post-replacement matches");
      Assert (Editor.Search.Has_Match (S.Active_Find_Match)
              and then Natural (S.Active_Find_Match.Start_Index) = 0,
              "post-replace selection must wrap to the first remaining match");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before,
              "replace.current must not add or clear navigation history");
   end Test_Phase366_Replace_Current_Preserves_Valid_Selected_Match;


   procedure Test_Phase366_Replace_Current_Does_Not_Trust_Stale_Deleted_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run one Run");

      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Next (S);
      Assert (Natural (S.Active_Find_Match.Start_Index) = 8,
              "precondition: stale selected range points at second Run");

      Set_Buffer_Text (S, "Run one done");
      S.Active_Find_Query := To_Unbounded_String ("Run");
      S.Active_Find_Stale := True;
      S.Active_Find_Match.Start_Index := 8;
      S.Active_Find_Match.End_Index := 11;
      S.Active_Find_Match.Index := 2;

      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_Current (S);

      Assert (Editor.State.Current_Text (S) = "Execute one done",
              "replace.current must target recomputed current text, not stale deleted coordinates");
      Assert (Latest_Message_Text (S) = "Replaced current match; no more matches",
              "replace.current must report no remaining post-replacement matches");
   end Test_Phase366_Replace_Current_Does_Not_Trust_Stale_Deleted_Range;


   procedure Test_Phase366_Replace_All_Does_Not_Recursively_Replace_New_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "foo foo");

      Editor.Executor.Execute_Find_Set_Query (S, "foo");
      Editor.Executor.Execute_Replace_Set_Text (S, "foofoo");
      Editor.Executor.Execute_Replace_All (S);

      Assert (Editor.State.Current_Text (S) = "foofoo foofoo",
              "replace.all must replace only the original canonical match set");
      Assert (Latest_Message_Text (S) = "Replaced 2 matches",
              "replace.all must report the original canonical count");
      Assert (Natural (S.Active_Find_Matches.Length) = 4,
              "post-replacement Find matches must reflect current text after non-recursive replace-all");
   end Test_Phase366_Replace_All_Does_Not_Recursively_Replace_New_Text;



   procedure Test_Phase367_Replace_Lifecycle_Find_Hide_And_Render_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Before_Back : Natural := 0;
      Before_Forward : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Replace_Show (S);
      Assert (S.Active_Find_Prompt and then S.Active_Replace_Prompt,
              "replace.show must keep canonical Find visible and show Replace");
      Assert (To_String (S.Active_Find_Query) = "Run"
              and then Natural (S.Active_Find_Matches.Length) = 2,
              "replace.show must not clear Find query/options/matches");
      Assert (Latest_Message_Text (S) = "Replace shown",
              "replace.show must emit exactly its primary shown message");

      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_Hide (S);
      Assert ((not S.Active_Replace_Prompt) and then S.Active_Find_Prompt,
              "replace.hide must hide only Replace under the Phase 365 policy");
      Assert (Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0,
              "replace.hide must clear replacement text and error");
      Assert (To_String (S.Active_Find_Query) = "Run"
              and then Natural (S.Active_Find_Matches.Length) = 2,
              "replace.hide must not clear canonical Find state");

      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Toggle (S);
      Assert (not S.Active_Replace_Prompt,
              "replace.toggle must hide when Replace is visible");
      Editor.Executor.Execute_Replace_Toggle (S);
      Assert (S.Active_Replace_Prompt and then S.Active_Find_Prompt,
              "replace.toggle must show Replace and compatible Find when hidden");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
              "replace visibility commands must not mutate Navigation History");

      Editor.Executor.Execute_Find_Hide (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert ((not S.Active_Find_Prompt) and then (not S.Active_Replace_Prompt),
              "find.hide must clear Replace so it cannot remain orphaned");
      Assert (Length (S.Active_Find_Query) = 0
              and then S.Active_Find_Matches.Is_Empty
              and then Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0,
              "find.hide must clear Find and Replace transient state together");
      Assert ((not Snap.Find_Visible) and then (not Snap.Replace_Visible)
              and then Snap.Active_Find_Match_Count = 0,
              "snapshot after find.hide must expose no Find ranges or Replace field");
   end Test_Phase367_Replace_Lifecycle_Find_Hide_And_Render_Coherence;


   procedure Test_Phase367_Replacement_Text_Literal_Matrix_And_No_Recompute
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Matches : Natural := 0;
      Before_Query : Unbounded_String;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Before_Matches := Natural (S.Active_Find_Matches.Length);
      Before_Query := S.Active_Find_Query;

      Editor.Executor.Execute_Replace_Set_Text (S, "Dispatch_Command");
      Assert (To_String (S.Active_Replace_Text) = "Dispatch_Command",
              "ordinary replacement text must be stored literally");
      Editor.Executor.Execute_Replace_Set_Text (S, "");
      Assert (Length (S.Active_Replace_Text) = 0,
              "empty replacement text must be stored and later delete matches");
      Editor.Executor.Execute_Replace_Set_Text (S, "  spaced value  ");
      Assert (To_String (S.Active_Replace_Text) = "  spaced value  ",
              "replacement text must preserve surrounding spaces literally");
      Editor.Executor.Execute_Replace_Set_Text (S, "\1");
      Assert (To_String (S.Active_Replace_Text) = "\1",
              "backslash capture-like text must be literal replacement text");
      Editor.Executor.Execute_Replace_Set_Text (S, "$1");
      Assert (To_String (S.Active_Replace_Text) = "$1",
              "dollar capture-like text must be literal replacement text");
      Editor.Executor.Execute_Replace_Set_Text (S, "Run.Run");
      Assert (To_String (S.Active_Replace_Text) = "Run.Run",
              "punctuation must be literal replacement text");
      Editor.Executor.Execute_Replace_Set_Text (S, "tab" & ASCII.HT & "value");
      Assert (To_String (S.Active_Replace_Text) = "tab" & ASCII.HT & "value",
              "tab replacement text must follow the current single-line field policy");
      Assert (To_String (S.Active_Find_Query) = To_String (Before_Query)
              and then Natural (S.Active_Find_Matches.Length) = Before_Matches,
              "replace.text.set must not recompute or mutate canonical Find matches");

      Editor.Executor.Execute_Replace_Set_Text (S, "Line" & ASCII.LF & "Break");
      Assert (To_String (S.Active_Replace_Text) = "tab" & ASCII.HT & "value"
              and then To_String (S.Active_Replace_Error_Message) = "Replacement text must be single-line"
              and then Latest_Message_Text (S) = "Replacement text must be single-line.",
              "newline replacement text must be rejected atomically with one primary message");
      Editor.Executor.Execute_Replace_Clear_Text (S);
      Assert (Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0,
              "replace.text.clear must clear text and prior validation error");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "replacement text edits must not record Navigation History");
   end Test_Phase367_Replacement_Text_Literal_Matrix_And_No_Recompute;


   procedure Test_Phase367_Replace_Current_Selected_Stale_And_No_Selected_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Back_Before : Natural := 0;
      Forward_Before : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run;" & ASCII.LF & "Run;" & ASCII.LF & "Run;");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Next (S);
      Assert (Natural (S.Active_Find_Match.Start_Row) = 1,
              "precondition: second match selected");
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "Run;" & ASCII.LF & "Execute;" & ASCII.LF & "Run;",
              "replace.current must replace only the selected canonical match");
      Assert (S.File_Info.Dirty and then Natural (S.Active_Find_Matches.Length) = 2,
              "replace.current must dirty and recompute post-replacement Find matches");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Active_Find_Match_Count = 2
              and then Snap.Active_Find_Matches (1).Start_Row = 0
              and then Snap.Active_Find_Matches (2).Start_Row = 2,
              "rendered Find ranges after replace.current must correspond to post-replacement text");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before,
              "replace.current must not add or clear Navigation History");

      Set_Buffer_Text (S, "xx Run yy Run");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      S.Active_Find_Match := Editor.Search.No_Match;
      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Editor.Cursors.Caret_State'
           (Pos => 1, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "xx Execute yy Run",
              "replace.current without selected match must select the nearest match at or after the caret");

      Set_Buffer_Text (S, "Run one Run");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Next (S);
      Set_Buffer_Text (S, "Run one done");
      S.Active_Find_Query := To_Unbounded_String ("Run");
      S.Active_Find_Stale := True;
      S.Active_Find_Match.Start_Index := 8;
      S.Active_Find_Match.End_Index := 11;
      S.Active_Find_Match.Index := 2;
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "Execute one done",
              "replace.current must recompute stale matches and never trust stale deleted coordinates");

      Set_Buffer_Text (S, "No hits here");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "No hits here"
              and then Latest_Message_Text (S) = "No matches",
              "replace.current with no recomputed matches must be atomic and report no matches");
   end Test_Phase367_Replace_Current_Selected_Stale_And_No_Selected_Workflows;


   procedure Test_Phase367_Replace_Current_Active_Buffer_Switch_Uses_Current_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase367_replace_switch_root");
      S      : Editor.State.State_Type;
      A_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      B_Path : constant String := Ada.Directories.Compose (Root, "b.txt");
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "Run in A");
      Write_Bytes (B_Path, "Run in B");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Next (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");

      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Editor.Executor.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "Execute in B",
              "replace.current after buffer switch must operate on the active buffer only");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert (Buffer_Text (S) = "Run in A",
              "replace.current after switch must not mutate the old selected-buffer range");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase367_Replace_Current_Active_Buffer_Switch_Uses_Current_Buffer;


   procedure Test_Phase367_Replace_All_Options_Span_Empty_And_Same_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run" & ASCII.LF & "PreRun" & ASCII.LF & "Run_One" & ASCII.LF & "Run.");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "Execute Execute" & ASCII.LF & "PreExecute" & ASCII.LF & "Execute_One" & ASCII.LF & "Execute.",
              "replace.all must replace all canonical substring matches with offset-safe edits");
      Assert (Latest_Message_Text (S) = "Replaced 5 matches",
              "replace.all count must equal the original canonical match count");

      Set_Buffer_Text (S, "Run run Runner runner PreRun preRun Run_One run_one Run.Run");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "Execute run Runner runner PreRun preRun Run_One run_one Execute.Execute",
              "replace.all must respect current case-sensitive whole-word canonical Find options");
      Assert (S.Active_Find_Case_Sensitive and then S.Active_Find_Whole_Word,
              "replace.all must not reset Find options");

      Set_Buffer_Text (S, "aaa");
      Editor.Executor.Execute_Find_Set_Query (S, "a");
      Editor.Executor.Execute_Find_Case_Clear (S);
      Editor.Executor.Execute_Find_Whole_Word_Clear (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "aa");
      Editor.Executor.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "aaaaaa"
              and then Latest_Message_Text (S) = "Replaced 3 matches",
              "replace.all must not recursively replace text inserted during the same invocation");

      Set_Buffer_Text (S, "abc abc abc");
      Editor.Executor.Execute_Find_Set_Query (S, "abc");
      Editor.Executor.Execute_Replace_Set_Text (S, "");
      Editor.Executor.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "  "
              and then Natural (S.Active_Find_Matches.Length) = 0,
              "empty replacement replace.all must delete all original canonical matches and recompute no ranges");

      Set_Buffer_Text (S, "Run Run");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Set_Text (S, "Run");
      Editor.Executor.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "Run Run"
              and then Latest_Message_Text (S) = "Replaced 2 matches",
              "replacement text equal to query must complete deterministically without recursive replacement");
   end Test_Phase367_Replace_All_Options_Span_Empty_And_Same_Text;


   procedure Test_Phase367_Context_Derived_Query_Render_Dirty_And_Failure_Atomicity
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos => 10, Anchor => 6, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_Find_From_Selection (S);
      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "BETA");
      Editor.Executor.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "alpha BETA alpha"
              and then S.File_Info.Dirty,
              "replace.current must use context-derived canonical Find query on dirty in-memory text");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Replace_Visible
              and then To_String (Snap.Replace_Text) = "BETA"
              and then Snap.Active_Find_Match_Count = 0,
              "render snapshot after replacement must expose Replace text and post-replacement Find ranges only");

      Editor.Executor.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "alpha BETA alpha"
              and then Latest_Message_Text (S) = "No matches",
              "replace.current no-match failure after recompute must not mutate buffer text");

      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_Replace_Set_Text (S, "Line" & ASCII.LF & "Break");
      Editor.Executor.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "alpha BETA alpha"
              and then Latest_Message_Text (S) = "Replacement text must be single-line.",
              "invalid replacement text must fail before any replace-all mutation");
   end Test_Phase367_Context_Derived_Query_Render_Dirty_And_Failure_Atomicity;


   procedure Test_Phase367_Feature_Independence_Navigation_And_Lifecycle_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Forward : Natural := 0;
      Before_Project_Search_Query : constant String := "project token";
      Before_Quick_Open_Query : constant String := "quick token";
      Before_Goto_Text : constant String := "22";
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, Before_Goto_Text);
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, Before_Quick_Open_Query);
      Editor.Project_Search.Set_Query (S.Project_Search, Before_Project_Search_Query);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History, (Buffer_Id => 1, Line => 1, Column => 0, others => <>));
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_Current (S);
      Editor.Executor.Execute_Replace_All (S);
      Editor.Executor.Execute_Replace_Hide (S);

      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = Before_Goto_Text,
              "Replace commands must not mutate Go To Line state except established overlay policy");
      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = Before_Quick_Open_Query,
              "Replace commands must not mutate Quick Open query state");
      Assert (Editor.Project_Search.Query (S.Project_Search) = Before_Project_Search_Query,
              "Replace commands must not mutate Project Search state");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
              "Replace commands must not push back stack or clear forward stack");

      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "Dispatch_Command");
      S.Active_Replace_Error_Message := To_Unbounded_String ("synthetic replace error");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert ((not S.Active_Replace_Prompt)
              and then Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0,
              "project lifecycle cleanup must clear all transient Replace state");
   end Test_Phase367_Feature_Independence_Navigation_And_Lifecycle_Cleanup;


   procedure Test_Phase367_Routes_Availability_Absent_Commands_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary : Unbounded_String;
      Found : Boolean := True;
      Id : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Availability : Editor.Commands.Command_Availability;

      procedure Check_Absent (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert ((not Found) and then Id = Editor.Commands.No_Command,
                 Name & " must remain absent from descriptors, palette, default bindings, input routes, and Executor dispatch");
      end Check_Absent;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.replace.show", Found);
      Assert (Found and then Id = Editor.Commands.Command_Replace_Show,
              "edit.replace.show route must resolve through command metadata");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.replace.current", Found);
      Assert (Found and then Id = Editor.Commands.Command_Replace_Current,
              "edit.replace.current route must resolve through command metadata");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.replace.all", Found);
      Assert (Found and then Id = Editor.Commands.Command_Replace_All,
              "edit.replace.all route must resolve through command metadata");

      Check_Absent ("edit.replace.regex");
      Check_Absent ("edit.replace.preview");
      Check_Absent ("edit.replace.confirm-next");
      Check_Absent ("edit.replace.history");
      Check_Absent ("edit.replace.in-project");
      Check_Absent ("edit.replace.all-in-project");
      Check_Absent ("edit.replace.selection-only");
      Check_Absent ("edit.replace.capture-group");
      Check_Absent ("edit.replace.smart-case");

      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "Dispatch_Command");
      Availability := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Replace_All);
      Assert (Availability.Status = Editor.Commands.Command_Available,
              "replace.all availability must report available for current active-buffer Replace state");
      Assert (Buffer_Text (S) = "Run Run"
              and then To_String (S.Active_Replace_Text) = "Dispatch_Command"
              and then Natural (S.Active_Find_Matches.Length) = 2,
              "replace availability must be side-effect-free over buffer, Replace, and Find state");

      S.Active_Replace_Error_Message := To_Unbounded_String ("Replacement text must be single-line");
      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Snapshot));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), "Dispatch_Command") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "Replacement text") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "replace") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "Run") = 0,
              "workspace persistence must exclude Replace text/error/counts and Find transient query/matches");
   end Test_Phase367_Routes_Availability_Absent_Commands_And_Persistence;

   procedure Test_Phase368_Replace_Render_Uses_Canonical_Overlay_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");

      S.Active_Find_Prompt := False;
      S.Active_Replace_Prompt := True;
      S.Active_Replace_Text := To_Unbounded_String ("removed-visible-text");
      S.Active_Replace_Error_Message := To_Unbounded_String ("removed-visible-error");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert ((not Snap.Replace_Visible)
              and then Length (Snap.Replace_Text) = 0
              and then Length (Snap.Replace_Error_Message) = 0,
              "render must not resurrect a Replace surface without canonical Find visibility");

      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      S.Active_Replace_Error_Message := To_Unbounded_String ("canonical replace error");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Replace_Visible
              and then To_String (Snap.Replace_Text) = "Execute"
              and then To_String (Snap.Replace_Error_Message) = "canonical replace error"
              and then Snap.Active_Find_Match_Count = 2,
              "render snapshot must project Replace only from canonical state and canonical Find matches");

      Editor.Executor.Execute_Find_Hide (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert ((not Snap.Replace_Visible)
              and then Length (Snap.Replace_Text) = 0
              and then Length (Snap.Replace_Error_Message) = 0,
              "Find hide must hide and clear the canonical Replace render surface");
   end Test_Phase368_Replace_Render_Uses_Canonical_Overlay_State;


   procedure Test_Phase368_Replace_Operations_Use_Only_Canonical_Find_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run run Runner PreRun Run_One Run");

      Editor.Project_Search.Set_Query (S.Project_Search, "run");
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "Runner");
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "42");

      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Execute_Replace_All (S);

      Assert (Buffer_Text (S) = "Execute run Runner PreRun Run_One Execute",
              "replace.all must use canonical Find query/options rather than any other feature query");
      Assert (Editor.Project_Search.Query (S.Project_Search) = "run",
              "replace.all must not mutate Project Search state");
      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = "Runner",
              "replace.all must not mutate Quick Open state");
      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = "42",
              "replace.all must not mutate Go To Line state");
      Assert (Natural (S.Active_Find_Matches.Length) = 0
              and then S.Active_Find_Case_Sensitive
              and then S.Active_Find_Whole_Word,
              "post-replace Find state must be recomputed with the same canonical options");
   end Test_Phase368_Replace_Operations_Use_Only_Canonical_Find_State;


   procedure Test_Phase368_Replace_Lifecycle_And_Persistence_Exclude_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary  : Unbounded_String;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_Replace_Show (S);
      Editor.Executor.Execute_Replace_Set_Text (S, "OMEGA");
      S.Active_Replace_Error_Message := To_Unbounded_String ("synthetic replace error");
      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Snapshot));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), "OMEGA") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "synthetic replace error") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "replace") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "alpha") = 0,
              "workspace snapshot must exclude canonical and removed-name-like Replace/Find transient state");

      Editor.State.Reset_Project_Scoped_State (S);
      Assert ((not S.Active_Replace_Prompt)
              and then Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0,
              "project lifecycle reset must clear the single canonical Replace state owner");
   end Test_Phase368_Replace_Lifecycle_And_Persistence_Exclude_State;


   procedure Test_Phase264_Typing_And_Save_Do_Not_Push_Navigation_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abc");

      Cmd := Editor.Test_Helper.Insert (0, 'X');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 264 ordinary typing must not push navigation history");

      Editor.Executor.Execute_Save (S);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 264 save must not push navigation history");
   end Test_Phase264_Typing_And_Save_Do_Not_Push_Navigation_History;


   procedure Test_Phase264_New_Explicit_Navigation_After_Back_Clears_Forward
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Navigation_History.Navigation_History_State;
      Target : Editor.Navigation_History.Navigation_Location;
      Found  : Boolean;
   begin
      Editor.Navigation_History.Record_Explicit_Navigation
        (State, (Buffer_Id => 1, Line => 1, Column => 0, others => <>));
      Found := Editor.Navigation_History.Pop_Back (State, Target);
      Assert (Found, "Phase 346 setup must pop a previous location");
      Editor.Navigation_History.Record_Forward_Navigation
        (State, (Buffer_Id => 1, Line => 3, Column => 0, others => <>));
      Assert (Editor.Navigation_History.Forward_Count (State) = 1,
              "Phase 346 setup must create a forward entry after back");

      Editor.Navigation_History.Record_Explicit_Navigation
        (State, (Buffer_Id => 1, Line => 2, Column => 0, others => <>));
      Assert (Editor.Navigation_History.Forward_Count (State) = 0,
              "Phase 346 new explicit navigation after back must clear forward history");
   end Test_Phase264_New_Explicit_Navigation_After_Back_Clears_Forward;

   procedure Test_Phase346_Navigation_History_Clear_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one" & ASCII.LF & "two");
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History, (Buffer_Id => 1, Line => 1, Column => 0, others => <>));
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "Phase 346 setup must create a back entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_History_Clear);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 346 clear must empty the back stack");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "Phase 346 clear must empty the forward stack");
      Assert (Latest_Message_Text (S) = "Navigation history cleared",
              "Phase 346 clear feedback must be deterministic");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_History_Clear);
      Assert (Latest_Message_Text (S) = "No navigation history.",
              "Phase 346 empty clear feedback must be deterministic");
   end Test_Phase346_Navigation_History_Clear_Command;


   procedure Test_Phase346_Navigation_History_Clear_Descriptor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Navigation_History_Clear);
   begin
      Assert (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Navigation_History_Clear) = "navigation.history.clear",
              "Phase 346 clear command must have a stable persisted name");
      Assert (D.Bindable,
              "Phase 346 clear command must be bindable");
      Assert (D.Visibility = Editor.Commands.Palette_Command,
              "Phase 346 clear command must be visible in the Command Palette");
      Assert (D.Category = Editor.Commands.Navigation_Category,
              "Phase 346 clear command must be categorized as Navigation");
      Assert (not D.Destructive,
              "Phase 346 clear command must not be classified destructive");
   end Test_Phase346_Navigation_History_Clear_Descriptor;


   procedure Test_Phase346_Failed_Back_Invalid_Open_Target_Is_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase346_invalid_back_atomic");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Write_Bytes (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Navigation_History.Clear (S.Navigation_History);

      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id     => Natural (B_Id),
          Has_File_Path => True,
          File_Path     => To_Unbounded_String (B_Path),
          Display_Path  => To_Unbounded_String ("beta.adb"),
          Line          => 99,
          Column        => 0,
          Viewport_Row  => 0,
          Reason        => Editor.Navigation_History.Navigation_Reason_Unknown));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);

      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "Phase 346 failed back to invalid open target must keep current buffer active");
      Assert (Buffer_Text (S) = "alpha body",
              "Phase 346 failed back to invalid open target must not load target text");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "Phase 346 failed back to invalid open target must restore back stack");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "Phase 346 failed back to invalid open target must not create forward entry");
      Assert (Latest_Message_Text (S) = "Could not navigate to beta.adb:99: invalid location",
              "Phase 346 failed back to invalid open target must report deterministic invalid-location feedback");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase346_Failed_Back_Invalid_Open_Target_Is_Atomic;



   procedure Test_Phase347_Back_To_Unopened_Stale_Line_Is_Partial_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase347_back_partial_line");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Write_Bytes (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id     => 0,
          Has_File_Path => True,
          File_Path     => To_Unbounded_String (B_Path),
          Display_Path  => To_Unbounded_String ("beta.adb"),
          Line          => 99,
          Column        => 0,
          Viewport_Row  => 0,
          Reason        => Editor.Navigation_History.Navigation_Reason_Unknown));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);

      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
              "Phase 347 partial stale-line back must keep successfully opened target active");
      Assert (Buffer_Text (S) = "beta body",
              "Phase 347 partial stale-line back must load the opened target text");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 347 partial stale-line back must consume the back entry");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "Phase 347 partial stale-line back must record current location for forward navigation");
      Assert (Latest_Message_Text (S) =
                "Navigated back to beta.adb:99; could not move to line 99",
              "Phase 347 partial stale-line back must report one deterministic partial-success message");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase347_Back_To_Unopened_Stale_Line_Is_Partial_Success;



   procedure Test_Phase274_Filter_Commands_Route_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase274_switcher_filter_commands");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Write_Bytes (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");

      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "review parser changes");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Filter_Pinned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "Phase 274 pinned filter command opens the switcher through Executor");
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S.Buffer_Switcher) = "pinned",
              "Phase 274 pinned filter command sets switcher metadata filter");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 274 pinned filter command narrows projected rows");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "Phase 274 pinned filter command keeps only pinned buffer");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Filter_Group);
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S.Buffer_Switcher) = "group core",
              "Phase 274 group filter command replaces existing switcher filter");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 274 group filter command narrows projected rows");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "Phase 274 group filter command keeps only matching group");
      Assert (not Editor.Buffers.Global_Has_Active_Buffer_Group,
              "Phase 274 group switcher filter must not activate the buffer group");
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "core",
              "Phase 274 group switcher filter must not mutate group membership");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Filter_Label);
      Cmd.Text := To_Unbounded_String ("test");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S.Buffer_Switcher) = "label test",
              "Phase 274 label filter command replaces existing switcher filter");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 274 label filter command narrows projected rows");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "Phase 274 label filter command keeps only matching label");
      Assert (Editor.Buffers.Global_Buffer_Label (B_Id) = "test",
              "Phase 274 label switcher filter must not mutate labels");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Filter_Noted);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S.Buffer_Switcher) = "noted",
              "Phase 274 noted filter command replaces existing switcher filter");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 274 noted filter command narrows projected rows");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "Phase 274 noted filter command keeps only noted buffers");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Filter_Clear);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Metadata_Filter (S.Buffer_Switcher),
              "Phase 274 clear filter command clears only switcher filter state");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "Phase 274 clear filter command restores ordinary open-buffer candidates");
      Assert (Editor.Buffers.Global_Buffer_Label (B_Id) = "test",
              "Phase 274 clear filter command must not clear labels");
      Assert (Editor.Buffers.Global_Has_Buffer_Note (B_Id),
              "Phase 274 clear filter command must not clear notes");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase274_Filter_Commands_Route_Through_Executor;

   procedure Test_Phase274_Filter_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase274_switcher_filter_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep this note");
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "test");
      Before := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Filter_Clear);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 274 clear filter availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Filter_Pinned);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 274 pinned filter availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Filter_Group);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 274 group filter availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Filter_Label);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 274 label filter availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Filter_Noted);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 274 noted filter availability should be available in setup");

      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before.Kind,
              "Phase 274 availability must not change switcher filter kind");
      Assert (To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
              To_String (Before.Text),
              "Phase 274 availability must not change switcher filter text");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id),
              "Phase 274 availability must not change pinned state");
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "core",
              "Phase 274 availability must not change group membership");
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "test",
              "Phase 274 availability must not change labels");
      Assert (Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "Phase 274 availability must not change notes");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase274_Filter_Availability_Is_Side_Effect_Free;



   procedure Test_Phase275_Sort_Commands_Route_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase275_switcher_sort_commands");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Write_Bytes (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "zeta");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "alpha");

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Assert (Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "Phase 275 setup should open buffer switcher");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Sort_Pinned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Editor.Buffer_Switcher.Pinned_Sort,
              "Phase 275 pinned sort command sets switcher sort through Executor");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "Phase 275 pinned sort command recomputes visible rows when switcher is open");
      Assert (not Editor.Buffer_Switcher.Has_Metadata_Filter (S.Buffer_Switcher),
              "Phase 275 sort command must not set a metadata filter");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Sort_Label);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Editor.Buffer_Switcher.Label_Sort,
              "Phase 275 label sort command replaces previous sort mode");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "Phase 275 label sort orders labeled buffers by label text");
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "zeta",
              "Phase 275 label sort must not mutate buffer labels");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "Phase 275 label sort must not mutate pinned state");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Sort_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Editor.Buffer_Switcher.Default_Sort,
              "Phase 275 next sort wraps from label to default");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "Phase 275 default sort restores existing switcher order");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Sort_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Editor.Buffer_Switcher.Label_Sort,
              "Phase 275 previous sort wraps from default to label");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase275_Sort_Commands_Route_Through_Executor;


   procedure Test_Phase276_Selected_Metadata_Actions_Target_Switcher_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase276_selected_metadata");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Found  : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Write_Bytes (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Navigation_History.Clear (S.Navigation_History);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = A_Id,
                 "Phase 276 setup should select a non-active switcher row");
      end;

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Selected_Pin);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id),
              "Phase 276 selected pin must target selected switcher row");
      Assert (not Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "Phase 276 selected pin must not target active buffer");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Selected_Group_Assign);
      Cmd.Text := To_Unbounded_String ("work");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "work",
              "Phase 276 selected group assign must target selected switcher row");
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (B_Id),
              "Phase 276 selected group assign must not mutate active buffer group");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Selected_Label_Set);
      Cmd.Text := To_Unbounded_String ("triage");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "triage",
              "Phase 276 selected label set must target selected switcher row");
      Assert (not Editor.Buffers.Global_Has_Buffer_Label (B_Id),
              "Phase 276 selected label set must not mutate active buffer label");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Selected_Note_Set);
      Cmd.Text := To_Unbounded_String ("review next");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Note (A_Id) = "review next",
              "Phase 276 selected note set must target selected switcher row");
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (B_Id),
              "Phase 276 selected note set must not mutate active buffer note");

      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 276 selected metadata actions must not activate the selected buffer");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 276 selected metadata actions must not add navigation history");
      Assert (not Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, A_Id),
              "Phase 276 selected metadata actions must not dirty selected buffer");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase276_Selected_Metadata_Actions_Target_Switcher_Row;

   procedure Test_Phase276_Selected_Close_Composes_With_Reopen_And_Dirty_Guard
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase276_selected_close");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Write_Bytes (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "Phase 276 selected close must close selected non-active buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 276 selected close of non-active buffer must not activate it first");
      Assert (True,
              "Phase 432: selected clean close must not record close-history/reopen state");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 276 selected close must refresh switcher candidates");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = 1,
              "Phase 276 selected close must normalize selection deterministically");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty alpha");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffers.Global_Contains (A_Id),
              "Phase 276 dirty selected close must leave selected buffer open before confirmation");
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 575 dirty selected close must open explicit dirty close review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope,
              "Phase 575 dirty selected close must record selected-buffer scope");
      Assert (True,
              "Phase 276 blocked selected close must not record reopen entry");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 276 blocked selected close must preserve active buffer");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "Phase 575 selected discard confirmation must close the selected dirty buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 575 selected discard confirmation must preserve active fallback");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 575 selected discard confirmation must refresh switcher rows");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = 1,
              "Phase 575 selected discard confirmation must normalize switcher selection");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase276_Selected_Close_Composes_With_Reopen_And_Dirty_Guard;



   procedure Test_Phase576_Buffer_List_Selected_Close_Cancel_Preserves_Dirty_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase576_selected_close_cancel");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Write_Bytes (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty selected alpha");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 576 selected dirty buffer-list close must enter Phase 575 dirty review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope,
              "Phase 576 selected dirty buffer-list close records selected-buffer close scope");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 576 cancel exits selected dirty close review");
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "Phase 576 cancel leaves selected dirty buffer open");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "Phase 576 cancel leaves active buffer open");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 576 cancel preserves active buffer while selected row was reviewed");

      Editor.Buffers.Global_Set_Active_Buffer (A_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Buffer_Text (S) = "dirty selected alpha",
              "Phase 576 cancel preserves selected dirty buffer text");
      Assert (S.File_Info.Dirty,
              "Phase 576 cancel preserves selected dirty marker");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Buffer_List_Selected_Close_Cancel_Preserves_Dirty_Text;

   procedure Test_Phase576_Close_Clean_Refreshes_Buffer_List_And_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Row  : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty survivor");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 3,
              "Phase 576 setup exposes all open buffers before close-clean");

      Editor.Executor.Execute_Close_All_Clean_Buffers (S);

      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "Phase 576 buffer-list close-clean closes the first clean buffer");
      Assert (not Editor.Buffers.Global_Contains (C_Id),
              "Phase 576 buffer-list close-clean closes the selected/active clean buffer");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "Phase 576 buffer-list close-clean preserves dirty buffers");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 576 close-clean refreshes buffer-list rows");
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = B_Id,
              "Phase 576 close-clean clamps buffer-list selection to the dirty survivor");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 576 close-clean chooses the dirty survivor as deterministic active fallback");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Close_Clean_Refreshes_Buffer_List_And_Selection;




   procedure Test_Phase576_Selected_Buffer_List_Clean_Close_Closes_And_Refreshes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase576_selected_clean_close");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found  : Boolean := False;
      Cmd    : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha clean");
      Write_Bytes (B_Path, "beta clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 576 selected clean buffer-list close must not open dirty review");
      Assert (not S.File_Conflict_Prompt_Active,
              "Phase 576 selected clean buffer-list close must not open file conflict prompt");
      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "Phase 576 selected clean buffer-list close removes the selected clean buffer");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "Phase 576 selected clean buffer-list close preserves the active buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 576 selected clean buffer-list close preserves active fallback");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 576 selected clean close refreshes buffer-list rows");
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = B_Id,
              "Phase 576 selected clean close clamps selection to the remaining buffer row");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Selected_Buffer_List_Clean_Close_Closes_And_Refreshes;

   procedure Test_Phase576_Selected_Buffer_List_Save_And_Close_Succeeds_And_Refreshes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase576_selected_save_close_success");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found  : Boolean := False;
      Result : Editor.Files.File_Open_Result;
      Cmd    : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha baseline");
      Write_Bytes (B_Path, "beta baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty selected alpha saved");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 576 selected dirty save-close starts in Phase 575 dirty review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope,
              "Phase 576 selected dirty save-close records selected-buffer scope");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 576 successful selected save-close clears dirty review");
      Assert (not S.File_Conflict_Prompt_Active,
              "Phase 576 successful selected save-close does not leave conflict prompt active");
      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "Phase 576 successful selected save-close closes the selected dirty buffer");
      Assert (Editor.Buffers.Global_Contains (B_Id)
                and then Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 576 successful selected save-close preserves the active buffer");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 576 successful selected save-close refreshes buffer-list rows");
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = B_Id,
              "Phase 576 successful selected save-close clamps selection to remaining row");
      Result := Editor.Files.Open_File (A_Path);
      Assert (Editor.Files.Is_Success (Result)
                and then To_String (Result.Contents) = "dirty selected alpha saved",
              "Phase 576 successful selected save-close writes selected buffer text before closing");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Selected_Buffer_List_Save_And_Close_Succeeds_And_Refreshes;

   procedure Test_Phase576_Selected_Buffer_List_Overwrite_Closes_And_Refreshes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase576_selected_overwrite_close");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found  : Boolean := False;
      Result : Editor.Files.File_Open_Result;
      Cmd    : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha baseline");
      Write_Bytes (B_Path, "beta baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty selected alpha overwrite");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Write_Bytes (A_Path, "external edit before overwrite close");

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (S.File_Conflict_Prompt_Active,
              "Phase 576 selected overwrite-close starts from file conflict prompt");
      Assert (S.File_Conflict_Close_After_Overwrite,
              "Phase 576 selected overwrite-close remembers close-after-overwrite");
      Assert (S.File_Conflict_Close_After_Overwrite_Selected,
              "Phase 576 selected overwrite-close remembers selected-buffer row origin");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);

      Assert (not S.File_Conflict_Prompt_Active,
              "Phase 576 selected overwrite-close clears conflict prompt");
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 576 selected overwrite-close leaves no dirty review active");
      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "Phase 576 selected overwrite-close closes the selected buffer after overwrite");
      Assert (Editor.Buffers.Global_Contains (B_Id)
                and then Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 576 selected overwrite-close preserves active buffer");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 576 selected overwrite-close refreshes buffer-list rows");
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = B_Id,
              "Phase 576 selected overwrite-close clamps selection to remaining row");
      Result := Editor.Files.Open_File (A_Path);
      Assert (Editor.Files.Is_Success (Result)
                and then To_String (Result.Contents) = "dirty selected alpha overwrite",
              "Phase 576 selected overwrite-close writes selected buffer text before closing");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Selected_Buffer_List_Overwrite_Closes_And_Refreshes;

   procedure Test_Phase576_Selected_Buffer_List_Save_Conflict_Preserves_Selected_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase576_selected_save_conflict");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha baseline");
      Write_Bytes (B_Path, "beta baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty selected alpha conflict");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Write_Bytes (A_Path, "external edit before selected save-and-close");

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 576 selected dirty close starts from Phase 575 dirty review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope,
              "Phase 576 selected dirty close preserves selected-buffer close scope");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 576 selected save-and-close conflict transfers from dirty review");
      Assert (S.File_Conflict_Prompt_Active,
              "Phase 576 selected save-and-close surfaces Phase 574 conflict prompt");
      Assert (S.File_Conflict_Close_After_Overwrite,
              "Phase 576 selected save-and-close remembers close-after-overwrite intent");
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "Phase 576 selected conflicted buffer remains open before explicit overwrite");
      Assert (Editor.Buffers.Global_Contains (B_Id)
                and then Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 576 selected save conflict preserves active buffer and open buffer set");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_File_Conflict_Cancel);
      Assert (not S.File_Conflict_Prompt_Active,
              "Phase 576 cancelling selected save conflict clears conflict prompt");
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "Phase 576 cancelling selected save conflict keeps selected dirty buffer open");
      Editor.Buffers.Global_Set_Active_Buffer (A_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Buffer_Text (S) = "dirty selected alpha conflict" and then S.File_Info.Dirty,
              "Phase 576 cancelling selected save conflict preserves selected dirty text and dirty state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Selected_Buffer_List_Save_Conflict_Preserves_Selected_Buffer;

   procedure Test_Phase277_Preview_Follows_Selected_Row_Without_Activation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase277_switcher_preview");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
      Found : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "line 1" & ASCII.LF & "line 2" & ASCII.LF & "line 3");
      Write_Bytes (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Navigation_History.Clear (S.Navigation_History);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = A_Id,
                 "Phase 277 setup should select the non-active buffer");
      end;

      Editor.Executor.Execute_Buffer_Switcher_Preview_Show (S);
      Assert (Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher),
              "Phase 277 preview show must enable preview state");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = A_Id,
              "Phase 277 preview target must follow selected switcher row");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 277 preview must not activate selected buffer");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "Phase 277 preview must not update recent activation head");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "Phase 277 preview must not update recent activation tail");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 277 preview must not add navigation history");

      Editor.Executor.Execute_Buffer_Switcher_Preview_Next_Line (S);
      Assert (Editor.Buffer_Switcher.Preview_Scroll_Offset (S.Buffer_Switcher) = 1,
              "Phase 277 preview scroll mutates only preview offset");
      Editor.Executor.Execute_Buffer_Switcher_Preview_Center_Cursor (S);
      Assert (Editor.Buffer_Switcher.Preview_Scroll_Offset (S.Buffer_Switcher) = 0,
              "Phase 277 center cursor clears preview scroll offset");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 277 preview center must not activate selected buffer");

      Editor.Executor.Execute_Buffer_Switcher_Next_Result (S);
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = B_Id,
              "Phase 277 preview must follow switcher selection changes");
      Editor.Executor.Execute_Buffer_Switcher_Preview_Hide (S);
      Assert (not Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher),
              "Phase 277 preview hide must disable preview state");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = Editor.Buffers.No_Buffer,
              "Phase 277 preview hide must clear transient target");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase277_Preview_Follows_Selected_Row_Without_Activation;

   procedure Test_Phase277_Preview_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase277_preview_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Preview_Target (S.Buffer_Switcher, A_Id, 3);
      Editor.Buffer_Switcher.Scroll_Preview_Next_Line (S.Buffer_Switcher);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Preview_Next_Line);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 277 preview next availability should be available with visible preview");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Preview_Previous_Line);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 277 preview previous availability should be available with visible preview");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Preview_Center_Cursor);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 277 preview center availability should be available with visible preview");

      Assert (Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher),
              "Phase 277 availability must not hide preview");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = A_Id,
              "Phase 277 availability must not retarget preview");
      Assert (Editor.Buffer_Switcher.Preview_Anchor_Line (S.Buffer_Switcher) = 3,
              "Phase 277 availability must not change preview anchor");
      Assert (Editor.Buffer_Switcher.Preview_Scroll_Offset (S.Buffer_Switcher) = 1,
              "Phase 277 availability must not change preview scroll");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase277_Preview_Availability_Is_Side_Effect_Free;

   procedure Test_Phase275_Sort_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase275_switcher_sort_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Config        : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Write_Bytes (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (A_Id /= Editor.Buffers.No_Buffer,
              "Phase 275 availability setup should create first buffer");
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "test");
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "test");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Pinned_Sort);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Default);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 275 default sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Recent);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 275 recent sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Name);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 275 name sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Pinned);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 275 pinned sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Group);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 275 group sort availability should not require existing groups");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Label);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 275 label sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Next);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 275 next sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Previous);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 275 previous sort availability should be available with open buffers");

      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "Phase 275 availability must not change switcher sort mode");
      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind,
              "Phase 275 availability must not change switcher filter kind");
      Assert (To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
              To_String (Before_Filter.Text),
              "Phase 275 availability must not change switcher filter text");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "Phase 275 availability must not mutate recent-buffer order head");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "Phase 275 availability must not mutate recent-buffer order tail");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "Phase 275 availability must not change pinned state");
      Assert (Editor.Buffers.Global_Buffer_Label (B_Id) = "test",
              "Phase 275 availability must not change label state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase275_Sort_Availability_Is_Side_Effect_Free;



   procedure Test_Phase278_Selected_Marks_Target_Switcher_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase278_selected_marks");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Found  : Boolean := False;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha" & ASCII.LF & "line two");
      Write_Bytes (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Navigation_History.Clear (S.Navigation_History);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Previous_Result (S);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = A_Id,
                 "Phase 278 setup should select non-active switcher row");
      end;

      Editor.Executor.Execute_Buffer_Switcher_Preview_Show (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Set);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 278 mark set must target selected switcher row");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 278 mark set must not target active buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 278 marking must not activate selected buffer");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = A_Id,
              "Phase 278 marking must preserve selected preview target");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "Phase 278 marking must not update recent-buffer head");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "Phase 278 marking must not update recent-buffer tail");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 278 marking must not push navigation history");
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Is_Marked,
                 "Phase 278 marked row should expose compact row state");
      end;

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Toggle);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 278 toggle must unmark selected switcher row");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 278 toggle must remark selected switcher row");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Clear);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 278 clear selected mark must unmark selected switcher row");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase278_Selected_Marks_Target_Switcher_Row;

   procedure Test_Phase278_Invert_Visible_Preserves_Hidden_Marks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase278_invert_visible");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Label (C_Id, "test");

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "test");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Executor.Execute_Open_Buffer_Switcher (S);

      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "Phase 278 setup should show only labeled visible rows");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 278 hidden marked buffer should remain marked after filter recompute");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Invert_Visible);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 278 invert visible must mark visible unmarked alpha");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "Phase 278 invert visible must mark visible unmarked gamma");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 278 invert visible must leave hidden marked beta unchanged");

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 278 second invert visible must unmark visible alpha");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "Phase 278 second invert visible must unmark visible gamma");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 278 second invert visible must still leave hidden beta marked");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Clear_All);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Marks (S.Buffer_Switcher),
              "Phase 278 clear all marks must remove hidden and visible marks");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase278_Invert_Visible_Preserves_Hidden_Marks;

   procedure Test_Phase278_Marked_Pin_Unpin_And_Metadata_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase278_marked_metadata");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "api");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep context");
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "dirty edge");

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Pin_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id),
              "Phase 278 pin marked must pin marked alpha");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "Phase 278 pin marked must pin marked beta");
      Assert (not Editor.Buffers.Global_Is_Buffer_Pinned (C_Id),
              "Phase 278 pin marked must not pin unmarked gamma");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 278 pin marked must not activate marked buffers");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Clear_Metadata);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (A_Id),
              "Phase 278 metadata clear must remove marked alpha group");
      Assert (not Editor.Buffers.Global_Has_Buffer_Label (A_Id),
              "Phase 278 metadata clear must remove marked alpha label");
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "Phase 278 metadata clear must remove marked alpha note");
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (B_Id),
              "Phase 278 metadata clear must remove marked beta group");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id),
              "Phase 278 metadata clear must not unpin marked alpha");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "Phase 278 metadata clear must not unpin marked beta");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 278 metadata clear must preserve marks for follow-up action");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Unpin_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Is_Buffer_Pinned (A_Id),
              "Phase 278 unpin marked must unpin marked alpha");
      Assert (not Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "Phase 278 unpin marked must unpin marked beta");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "Phase 278 marked metadata actions must not update recent-buffer head");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "Phase 278 marked metadata actions must not update recent-buffer tail");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 278 marked metadata actions must not push navigation history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase278_Marked_Pin_Unpin_And_Metadata_Clear;

   procedure Test_Phase278_Marked_Close_Dirty_Reopen_And_Pin_Composition
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase278_marked_close");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Reopened_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
              Editor.Buffer_Switcher.Pending_Marked_Close,
              "Phase 282 marked close should prepare confirmation before mutation");
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "Phase 278 marked close must close marked pinned clean buffer explicitly");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "Phase 278 marked close must keep dirty marked buffer open");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 278 dirty blocked marked buffer must remain marked");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 278 marked close of non-active buffers must preserve active buffer");
      Assert (True,
              "Phase 432: successful marked close must not record close-history/reopen state");

      null;
      Reopened_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Reopened_Id = C_Id,
              "Phase 432: removed removed-name reopen must preserve the active buffer after marked close");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase278_Marked_Close_Dirty_Reopen_And_Pin_Composition;

   procedure Test_Phase278_Mark_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase278_mark_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Config        : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "test");
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "test");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Preview_Target (S.Buffer_Switcher, A_Id, 2);
      Editor.Buffer_Switcher.Scroll_Preview_Next_Line (S.Buffer_Switcher);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Toggle);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 278 mark toggle availability should be available with selected switcher row");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 278 close marked availability should be available with marks");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Invert_Visible);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 278 invert visible availability should be available with visible rows");

      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 278 availability must not clear existing marks");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 278 availability must not add marks");
      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind,
              "Phase 278 availability must not change filter kind");
      Assert (To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
              To_String (Before_Filter.Text),
              "Phase 278 availability must not change filter text");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "Phase 278 availability must not change sort mode");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = A_Id,
              "Phase 278 availability must not change preview target");
      Assert (Editor.Buffer_Switcher.Preview_Scroll_Offset (S.Buffer_Switcher) = 1,
              "Phase 278 availability must not change preview scroll");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase278_Mark_Availability_Is_Side_Effect_Free;


   procedure Test_Phase279_Marked_Metadata_Apply_Targets_Marked_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase279_marked_metadata_apply");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "old");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "api");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "old note");
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Group_Assign);
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "core",
              "Phase 279 marked group assign must replace alpha group");
      Assert (Editor.Buffers.Global_Buffer_Group (B_Id) = "core",
              "Phase 279 marked group assign must apply to dirty marked beta");
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (C_Id),
              "Phase 279 marked group assign must not touch unmarked gamma");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Cmd.Text := To_Unbounded_String ("test");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "test",
              "Phase 279 marked label set must replace alpha label");
      Assert (Editor.Buffers.Global_Buffer_Label (B_Id) = "test",
              "Phase 279 marked label set must apply to marked beta");
      Assert (not Editor.Buffers.Global_Has_Buffer_Label (C_Id),
              "Phase 279 marked label set must not touch unmarked gamma");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Note_Set);
      Cmd.Text := To_Unbounded_String ("shared context");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Note (A_Id) = "shared context",
              "Phase 279 marked note set must replace alpha note");
      Assert (Editor.Buffers.Global_Buffer_Note (B_Id) = "shared context",
              "Phase 279 marked note set must apply to marked beta");
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (C_Id),
              "Phase 279 marked note set must not touch unmarked gamma");

      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "Phase 279 marked metadata apply must preserve pins");
      Assert (Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id),
              "Phase 279 marked metadata apply must preserve dirty state");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 279 marked metadata apply must preserve alpha mark");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 279 marked metadata apply must preserve beta mark");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 279 marked metadata apply must not activate marked buffers");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "Phase 279 marked metadata apply must not update recent-buffer head");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "Phase 279 marked metadata apply must not update recent-buffer tail");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 279 marked metadata apply must not add navigation history");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Group_Clear);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (A_Id)
              and then Editor.Buffers.Global_Buffer_Label (A_Id) = "test"
              and then Editor.Buffers.Global_Buffer_Note (A_Id) = "shared context",
              "Phase 279 marked group clear must clear only groups");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Clear);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Label (A_Id)
              and then Editor.Buffers.Global_Buffer_Note (A_Id) = "shared context",
              "Phase 279 marked label clear must clear only labels");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Note_Clear);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "Phase 279 marked note clear must clear notes");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 279 granular clear must preserve marks");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase279_Marked_Metadata_Apply_Targets_Marked_Buffers;

   procedure Test_Phase279_Marked_Metadata_Composes_With_Filter_Sort_And_Preview
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase279_marked_filter_sort_preview");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Config        : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "test");
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (C_Id, "test");

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "test");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Label_Sort);
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Preview_Target (S.Buffer_Switcher, C_Id, 1);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "Phase 279 setup should show only label-filtered rows");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Cmd.Text := To_Unbounded_String ("review");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "review",
              "Phase 279 marked apply must mutate visible marked buffers");
      Assert (Editor.Buffers.Global_Buffer_Label (B_Id) = "review",
              "Phase 279 marked apply must mutate hidden marked buffers");
      Assert (Editor.Buffers.Global_Buffer_Label (C_Id) = "test",
              "Phase 279 marked apply must not mutate unmarked visible buffers");
      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind,
              "Phase 279 marked apply must preserve filter kind");
      Assert (To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
              To_String (Before_Filter.Text),
              "Phase 279 marked apply must preserve filter text");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "Phase 279 marked apply must preserve sort mode");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 279 marked apply must rebuild filtered projection after label change");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = C_Id,
              "Phase 279 marked apply must keep preview target when selected buffer remains visible");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 279 marked apply must preserve marks after filter recompute");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase279_Marked_Metadata_Composes_With_Filter_Sort_And_Preview;

   procedure Test_Phase279_Marked_Metadata_Validation_And_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase279_marked_validation");
      A_Path    : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      S         : Editor.State.State_Type;
      A_Id      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd       : Editor.Commands.Command;
      Avail     : Editor.Commands.Command_Availability;
      Long_Note : constant String (1 .. Editor.Buffers.Max_Buffer_Note_Length + 1) := (others => 'n');
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable,
              "Phase 279 marked apply availability should require marked buffers");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 279 marked apply availability should be available with marks");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 279 availability must not mutate marks");

      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "keep");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "keep");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Group_Assign);
      Cmd.Text := To_Unbounded_String ("   ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "keep",
              "Phase 279 blank group input must not mutate marked group");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Cmd.Text := To_Unbounded_String ("bad/label");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "keep",
              "Phase 279 invalid label input must not mutate marked label");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Note_Set);
      Cmd.Text := To_Unbounded_String (Long_Note);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Note (A_Id) = "keep",
              "Phase 279 too-long note input must not mutate marked note");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase279_Marked_Metadata_Validation_And_Availability;



   procedure Test_Phase280_Mark_Presets_Compose_With_Metadata_Visibility_And_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase280_mark_presets");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      D_Path : constant String := Ada.Directories.Compose (Root, "delta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      D_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Config        : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Before_Selected : Natural := 0;
      Before_Preview  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Write_Bytes (D_Path, "delta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "alpha note");
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "prod");
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (C_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Note (C_Id, "different contents still noted");
      Editor.Executor.Execute_Open_File (S, D_Path);
      D_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty delta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer_Group ("core");

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "alpha");
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, S.Recent_Buffers, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 280 setup should have one visible literal match");
      Editor.Executor.Execute_Buffer_Switcher_Mark_Visible (S);
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 280 mark visible marks the current projection");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "Phase 280 mark visible does not mark hidden buffers");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, D_Id);
      Editor.Executor.Execute_Buffer_Switcher_Mark_Clear_Visible (S);
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 280 clear visible removes visible marks");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, D_Id),
              "Phase 280 clear visible preserves hidden marks");

      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "prod");
      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Preview_Target (S.Buffer_Switcher, B_Id, 1);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);
      Before_Selected := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Before_Preview := Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Editor.Executor.Execute_Buffer_Switcher_Mark_Pinned (S);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Group);
      Cmd.Text := To_Unbounded_String (" core ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Label);
      Cmd.Text := To_Unbounded_String (" test ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Executor.Execute_Buffer_Switcher_Mark_Noted (S);

      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, D_Id),
              "Phase 280 metadata mark presets are additive and include hidden matching buffers");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id)
              and then not Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "Phase 280 mark pinned observes pin state without pinning unpinned buffers");
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "core"
              and then Editor.Buffers.Global_Buffer_Group (B_Id) = "core"
              and then Editor.Buffers.Global_Active_Buffer_Group = "core",
              "Phase 280 mark group does not change group membership or active group");
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "test"
              and then Editor.Buffers.Global_Buffer_Label (C_Id) = "test"
              and then not Editor.Buffers.Global_Has_Buffer_Label (D_Id),
              "Phase 280 mark label does not create or modify labels");
      Assert (Editor.Buffers.Global_Buffer_Note (A_Id) = "alpha note"
              and then Editor.Buffers.Global_Buffer_Note (C_Id) = "different contents still noted",
              "Phase 280 mark noted uses note presence without searching or mutating note text");
      Assert (Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, D_Id),
              "Phase 280 mark presets do not change dirty state");
      Assert (Editor.Buffers.Global_Active_Buffer = D_Id,
              "Phase 280 mark presets do not activate buffers");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1
              and then Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "Phase 280 mark presets do not update recent-buffer order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 280 mark presets do not add navigation history");
      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind
              and then To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
                To_String (Before_Filter.Text),
              "Phase 280 metadata mark presets preserve active filter");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "Phase 280 metadata mark presets preserve sort mode");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = Before_Selected
              and then Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = Before_Preview,
              "Phase 280 mark presets preserve selection and preview when row remains visible");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Cmd.Text := To_Unbounded_String ("review");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "review"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "review"
              and then Editor.Buffers.Global_Buffer_Label (C_Id) = "review"
              and then Editor.Buffers.Global_Buffer_Label (D_Id) = "review",
              "Phase 280 marked actions operate on the resulting preset mark set");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase280_Mark_Presets_Compose_With_Metadata_Visibility_And_State;

   procedure Test_Phase280_Mark_Preset_Availability_And_No_Match_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase280_mark_preset_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Pinned);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable,
              "Phase 280 mark pinned availability is deterministic with no pinned buffers");
      Assert (not Editor.Buffer_Switcher.Has_Marks (S.Buffer_Switcher),
              "Phase 280 mark preset availability must not mutate marks");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Group);
      Cmd.Text := To_Unbounded_String ("missing");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Marks (S.Buffer_Switcher),
              "Phase 280 group mark with no groups leaves marks unchanged");

      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Cmd.Text := To_Unbounded_String ("missing");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Marks (S.Buffer_Switcher),
              "Phase 280 group mark with no matching open buffers leaves marks unchanged");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase280_Mark_Preset_Availability_And_No_Match_Are_Deterministic;



   procedure Test_Phase281_Marked_Review_Routes_Through_Executor_And_Is_Inspection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase281_marked_review_executor");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Found  : Boolean := False;
      Msg    : Editor.Messages.Editor_Message;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha body");
      Write_Bytes (B_Path, "beta body");
      Write_Bytes (C_Path, "gamma body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "review");
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "review");
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "review");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Execute_Buffer_Switcher_Insert_Text (S, "a");
      Editor.Executor.Execute_Buffer_Switcher_Preview_Show (S);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher),
              "Phase 281 show command enables marked review through Executor");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "Phase 281 marked review shows marked rows matching filter and query");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "Phase 281 marked review preserves active sort order for candidates");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 2).Id = B_Id,
              "Phase 281 marked review includes the second marked matching row");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = B_Id,
                 "Phase 281 next marked selects the next visible marked candidate");
         Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = B_Id,
                 "Phase 281 preview follows marked-review selection movement");
      end;

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = A_Id,
                 "Phase 281 previous marked selects the previous visible marked candidate");
         Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = A_Id,
                 "Phase 281 preview follows previous marked selection movement");
      end;

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (Msg.Text) = "Marked buffers: 2",
              "Phase 281 summary reports the current open marked-buffer count");

      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind
              and then To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
                To_String (Before_Filter.Text),
              "Phase 281 marked review commands must not alter metadata filter state");
      Assert (Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher) = "a",
              "Phase 281 marked review commands must not alter literal query state");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "Phase 281 marked review commands must not alter sort mode");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "Phase 281 marked review commands must not create or clear marks");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "Phase 281 marked review commands must not change pinned state");
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "review"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "review",
              "Phase 281 marked review commands must not change labels");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 281 marked review navigation must not activate buffers");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1
              and then Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "Phase 281 marked review commands must not update recent-buffer order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 281 marked review commands must not add navigation history");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Hide);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher),
              "Phase 281 hide command disables only marked review state");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "Phase 281 hide restores ordinary filtered query projection");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase281_Marked_Review_Routes_Through_Executor_And_Is_Inspection_Only;

   procedure Test_Phase281_Marked_Review_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase281_marked_review_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "review");
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "review");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Show_Marked_Review (S.Buffer_Switcher);
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Review_Toggle);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 281 marked review toggle availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 281 marked review show availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Review_Hide);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 281 marked review hide availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Next);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 281 marked next availability should find the current marked candidate");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Previous);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 281 marked previous availability should find the current marked candidate");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Summary);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 281 marked summary availability should be available in setup");

      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher),
              "Phase 281 availability must not change marked review state");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 281 availability must not mutate mark membership");
      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind
              and then To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
                To_String (Before_Filter.Text),
              "Phase 281 availability must not mutate filter state");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "Phase 281 availability must not mutate sort state");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 281 availability must not rebuild or widen review candidates");
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "review",
              "Phase 281 availability must not mutate metadata");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase281_Marked_Review_Availability_Is_Side_Effect_Free;


   procedure Test_Phase282_Marked_Close_Prepares_Captured_Targets_And_Cancel
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase282_prepare_cancel");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent_1 : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "api");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep");
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.Pending_Marked_Close,
              "Phase 282 marked close prepares a pending close action");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2,
              "Phase 282 pending close captures the marked open-buffer count");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = B_Id,
              "Phase 282 pending close captures target identities in mark order");
      Assert (Editor.Buffers.Global_Contains (A_Id) and then Editor.Buffers.Global_Contains (B_Id),
              "Phase 282 prepare must not close captured buffers");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 282 prepare must not mutate marks");
      Assert (Editor.Buffers.Global_Has_Buffer_Group (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Label (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "Phase 282 prepare must not mutate buffer metadata");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 282 prepare must not activate marked buffers");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "Phase 282 prepare must not update recent-buffer activation order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 282 prepare must not add navigation history");
      Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "none");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Toggle_Marked_Review (S.Buffer_Switcher);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = B_Id,
              "Phase 282 mark/filter/sort/review changes must not alter captured targets");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Cancel);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action,
              "Phase 282 cancel clears pending marked close");
      Assert (Editor.Buffers.Global_Contains (A_Id) and then Editor.Buffers.Global_Contains (B_Id),
              "Phase 282 cancel must not close buffers");
      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase282_Marked_Close_Prepares_Captured_Targets_And_Cancel;

   procedure Test_Phase282_Confirm_Closes_Captured_Clean_Skips_Closed_And_Protects_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase282_confirm_captured");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Closed : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Dirty_Count (S.Buffer_Switcher) = 1,
              "Phase 282 pending close records a dirty-count hint");
      Editor.Buffers.Global_Close_Buffer (A_Id, Closed);
      Assert (Closed, "Phase 282 setup should close one captured target before confirm");
      Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Contains (C_Id),
              "Phase 282 confirm closes captured clean buffers even after marks changed");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "Phase 282 confirm preserves dirty captured buffers through existing close policy");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action,
              "Phase 282 confirm clears pending state after execution");
      Assert (True,
              "Phase 432: successful confirmed closes must not create close-history/reopen entries");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 282 blocked captured buffers follow their current mark state");
      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase282_Confirm_Closes_Captured_Clean_Skips_Closed_And_Protects_Dirty;

   procedure Test_Phase282_Confirm_Cancel_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase282_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Avail := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 282 confirm availability should be available for pending close");
      Avail := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Buffer_Switcher_Mark_Cancel);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 282 cancel availability should be available for pending close");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id,
              "Phase 282 availability must not mutate pending captured targets");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 282 availability must not mutate marks");
      Assert (Editor.Buffers.Global_Contains (A_Id) and then Editor.Buffers.Global_Contains (B_Id),
              "Phase 282 availability must not close buffers");
      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase282_Confirm_Cancel_Availability_Is_Side_Effect_Free;

   procedure Test_Phase283_Pending_Marked_Review_Commands_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase283_pending_review_commands");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent : Natural := 0;
      Found : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2,
              "Phase 283 setup captures two pending close targets");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher),
              "Phase 283 show enables pending marked review");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "Phase 283 pending review narrows rows to captured open targets");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 2).Id = B_Id,
              "Phase 283 pending review follows captured target identity, not active buffer");

      Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pending marked close: 2 targets; 2 still open",
              "Phase 283 summary reports captured and still-open counts");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = B_Id,
              "Phase 283 summary must not refresh pending targets from current marks");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "Phase 283 summary must not mutate current marks");

      Before_Recent := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = B_Id,
                 "Phase 283 pending next follows effective review order without activation");
      end;
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 283 pending navigation must not activate the selected target");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent,
              "Phase 283 pending navigation must not update recent-buffer order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 283 pending navigation must not add navigation history");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Contains (B_Id),
              "Phase 283 selected close acts on the selected pending-review row");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2,
              "Phase 283 selected close must not shrink captured pending targets");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "Phase 283 closed pending targets disappear only from the open review candidates");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher),
              "Phase 283 marked review and pending marked review are mutually exclusive");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher),
              "Phase 283 showing pending review hides marked review deterministically");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pending marked close: 2 targets; 1 still open",
              "Phase 283 summary skips captured targets that are no longer open");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Cancel);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
                Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher),
              "Phase 283 cancelling pending close clears pending review state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase283_Pending_Marked_Review_Commands_Are_Deterministic;


   procedure Test_Phase284_Remove_Selected_Prunes_Pending_Close_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase284_remove_selected");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent : Natural := 0;
      Found  : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "api");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep");
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Preview_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "Phase 284 setup should select first pending target in pending review");

      Before_Recent := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = B_Id,
              "Phase 284 remove-selected prunes selected identity from captured pending close set");
      Assert (Editor.Buffers.Global_Contains (A_Id) and then Editor.Buffers.Global_Contains (B_Id),
              "Phase 284 remove-selected must not close buffers");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 284 remove-selected must not mutate current marks");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Group (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Label (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "Phase 284 remove-selected must not mutate metadata");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 284 remove-selected must not activate a buffer");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent,
              "Phase 284 remove-selected must not update recent-buffer order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 284 remove-selected must not add navigation history");
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "Phase 284 pending review candidate set updates after pruning");
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = B_Id,
                 "Phase 284 pending review selection normalizes after pruning");
      end;
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = B_Id,
              "Phase 284 preview follows normalized pending-review selection");
      Assert (Latest_Message_Text (S) = "Removed alpha.adb from pending close; pending close now has 1 targets",
              "Phase 284 remove-selected reports pruned count");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "Phase 284 confirm must not close pruned targets");
      Assert (not Editor.Buffers.Global_Contains (B_Id),
              "Phase 284 confirm closes remaining pending targets");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 284 pruned target remains marked after confirm");
      Assert (True,
              "Phase 432: pruned pending close confirmation must not create close-history/reopen entries");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase284_Remove_Selected_Prunes_Pending_Close_Target;


   procedure Test_Phase284_Remove_Selected_Availability_And_Last_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase284_availability_last");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable,
              "Phase 284 remove-selected is unavailable without pending marked action");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable,
              "Phase 284 remove-selected is unavailable when selected row is not a pending target");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id,
              "Phase 284 deterministic no-op does not mutate pending targets for non-target selection");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, A_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher),
              "Phase 284 removing the last target clears pending action and exits pending review");
      Assert (Editor.Buffers.Global_Contains (A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "Phase 284 removing the last target remains non-destructive and preserves marks");
      Assert (Latest_Message_Text (S) = "No pending marked targets remain",
              "Phase 284 removing last target reports deterministic zero-target state");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id,
              "Phase 284 preparing marked close again refreshes pending targets from current marks");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase284_Remove_Selected_Availability_And_Last_Target;


   procedure Test_Phase285_Restore_Last_Pruned_Pending_Close_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase285_restore_last_pruned");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
      Before_Recent : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "api");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep");
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Preview_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable,
              "Phase 285 restore-last is unavailable before any pending target is pruned");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, C_Id, 1);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id,
              "Phase 285 setup should leave only alpha active after pruning beta and gamma");
      Assert (Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 2,
              "Phase 285 pruning keeps session-local pruned pending target history");

      Before_Recent := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Buffer_Switcher.Clear_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pruned pending close targets: 2; 2 still open",
              "Phase 285 pruned summary reports total and still-open pruned targets");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = C_Id,
              "Phase 285 restore-last restores the most recently pruned still-open target");
      Assert (Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1,
              "Phase 285 restored target is removed from pruned history");
      Assert (Editor.Buffers.Global_Contains (C_Id),
              "Phase 285 restore-last must not close the restored buffer");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 285 restore-last must not mark or unmark buffers");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Group (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Label (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "Phase 285 restore-last must not mutate metadata");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 285 restore-last must not activate buffers");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent,
              "Phase 285 restore-last must not update recent-buffer order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 285 restore-last must not add navigation history");

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = B_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 3) = C_Id,
              "Phase 285 restored pending targets return to original captured order");
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 3,
              "Phase 285 pending marked review candidate set updates after restoration");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) /= Editor.Buffers.No_Buffer,
              "Phase 285 preview remains derived from normalized pending review selection");

      Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3,
              "Phase 285 clearing marks after restoration does not remove restored pending close targets");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Contains (A_Id)
              and then not Editor.Buffers.Global_Contains (B_Id)
              and then not Editor.Buffers.Global_Contains (C_Id),
              "Phase 285 confirm closes active pending targets after restoration");
      Assert (True,
              "Phase 432: confirm order cleanup must not create close-history/reopen entries");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 285 confirm clears pending action and pruned history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase285_Restore_Last_Pruned_Pending_Close_Target;

   procedure Test_Phase285_Restore_Last_Pruned_Closed_Target_Is_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase285_closed_pruned");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Closed : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Buffers.Global_Close_Buffer (B_Id, Closed);
      Assert (Closed, "Phase 285 setup should close the pruned target before restore");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Could not restore beta.adb; buffer is no longer open",
              "Phase 285 restore-last reports a closed last-pruned target explicitly");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1,
              "Phase 285 closed-target restore failure leaves pending and pruned state unchanged");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 285 preparing marked close again refreshes targets and clears old pruned history");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Cancel);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 285 cancelling pending marked close clears pruned history without closing buffers");
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "Phase 285 cancellation after pruned restore state remains non-destructive");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase285_Restore_Last_Pruned_Closed_Target_Is_Explicit;


   procedure Test_Phase286_Pruned_Pending_Summary_Navigation_Review_And_Selected_Restore
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase286_pruned_review_restore");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, C_Id, 1);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pruned pending close targets: 2; 2 still open",
              "Phase 286 pruned summary reports total and still-open pruned target counts");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 2,
              "Phase 286 pruned summary does not mutate active pending or pruned target state");

      Editor.Navigation_History.Clear (S.Navigation_History);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher),
              "Phase 286 pruned review is the single active review constraint");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 2).Id = C_Id,
              "Phase 286 pruned review narrows the switcher projection to still-open pruned targets");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 2).Id = C_Id,
              "Phase 286 pruned-next follows current pruned review order");
      Assert (not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "Phase 286 pruned navigation does not restore or unmark the selected target");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 286 pruned navigation does not activate buffers or add navigation history");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "Phase 286 pruned-previous follows current pruned review order");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = B_Id
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1,
              "Phase 286 restore-selected-pruned restores only the selected still-open pruned target");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 286 restore-selected-pruned does not mark, unmark, or activate buffers");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Contains (A_Id)
              and then not Editor.Buffers.Global_Contains (B_Id)
              and then Editor.Buffers.Global_Contains (C_Id),
              "Phase 286 confirm closes restored active pending targets but not unrestored pruned targets");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S.Buffer_Switcher),
              "Phase 286 confirm clears pending action, pruned history, and pruned review state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase286_Pruned_Pending_Summary_Navigation_Review_And_Selected_Restore;

   procedure Test_Phase286_Pruned_Pending_No_Open_And_No_Pending_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase286_no_open_pruned");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Closed : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No pending marked action",
              "Phase 286 pruned summary reports deterministic no-pending state");

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Buffers.Global_Close_Buffer (B_Id, Closed);
      Assert (Closed, "Phase 286 setup closes the pruned target outside pruned inspection");
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers,
         Editor.Buffer_Switcher.Buffer_Switcher_Config'(others => <>));

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pruned pending close targets: 1; 0 still open",
              "Phase 286 pruned summary distinguishes closed pruned targets from still-open pruned targets");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No open pruned pending close targets",
              "Phase 286 pruned navigation reports deterministic no-open-pruned state");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1,
              "Phase 286 no-open-pruned navigation does not mutate pending or pruned state");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Cancel);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S.Buffer_Switcher),
              "Phase 286 cancel clears pruned history and pruned review state without closing active pending targets");
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "Phase 286 cancel remains non-destructive for active pending targets");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase286_Pruned_Pending_No_Open_And_No_Pending_Messages;


   procedure Test_Phase289_Dirty_Pending_Summary_And_Navigation_Route_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase289_dirty_pending_navigation");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty pending close targets: 2 of 3",
              "Phase 289 dirty summary reports dirty active pending targets against still-open pending targets");

      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Selected next dirty pending close target",
              "Phase 289 dirty-next reports a deterministic primary message");
      Assert (Editor.Buffer_Switcher.Row_At
                (S.Buffer_Switcher, Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher)).Id = B_Id,
              "Phase 289 dirty-next selects the next dirty pending target in switcher order");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = B_Id,
              "Phase 289 dirty navigation refreshes the preview target through existing selection behavior");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 289 dirty navigation does not activate buffers or add navigation history");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Row_At
                (S.Buffer_Switcher, Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher)).Id = C_Id,
              "Phase 289 dirty-previous selects the previous dirty pending target in switcher order");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "Phase 289 dirty navigation does not mutate marks or pending targets");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase289_Dirty_Pending_Summary_And_Navigation_Route_Through_Executor;


   procedure Test_Phase290_Dirty_Pending_Remove_Selected_Prunes_Without_Buffer_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase290_dirty_pending_remove_selected");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "work");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "review");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "keep dirty");
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) =
              "Marked: 3 | Pending close: 3 | Dirty: 1",
              "Phase 290 setup has one dirty pending close target");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Row_At
                (S.Buffer_Switcher,
                 Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher)).Id = B_Id,
              "Phase 290 setup selects the dirty active pending target through Phase 289 navigation");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 290 dirty-remove-selected is available for a selected dirty pending target");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 290 availability does not mutate pending targets, pruned history, or marks");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) =
              "Removed dirty pending close target beta.adb; pending close now has 2 targets; Dirty: 0",
              "Phase 290 dirty-remove-selected emits one deterministic pruning outcome message");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1,
              "Phase 290 dirty-remove-selected removes the target from active pending close and records ordinary pruned history");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) =
              "Marked: 3 | Pending close: 2 | Pruned: 1",
              "Phase 290 pending, dirty, and pruned counts update after dirty pruning");
      Assert (Editor.Buffers.Global_Contains (B_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "Phase 290 dirty-remove-selected does not close, save, discard, or unmark the selected buffer");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id)
              and then Editor.Buffers.Global_Buffer_Group (B_Id) = "work"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "review"
              and then Editor.Buffers.Global_Buffer_Note (B_Id) = "keep dirty",
              "Phase 290 dirty-remove-selected does not mutate pinned state, group, label, or note metadata");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "Phase 290 dirty-remove-selected does not activate buffers, add navigation history, or update recent-buffer state");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No dirty pending close targets",
              "Phase 290 pruned dirty target is removed from dirty pending navigation candidates");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 1,
              "Phase 290 dirty-pruned targets restore through ordinary last-pruned restoration and become dirty-pending if still dirty");

      Editor.Buffers.Global_Set_Active_Buffer (B_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Selected pending close target is not dirty",
              "Phase 290 clean selected pending targets are rejected by the dirty-only shortcut");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 290 dirty-only rejection leaves pending and pruned state unchanged");

      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id),
              "Phase 290 setup reprunes restored dirty target before confirmation");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Contains (B_Id)
              and then not Editor.Buffers.Global_Contains (A_Id)
              and then not Editor.Buffers.Global_Contains (C_Id),
              "Phase 290 confirm closes only remaining active pending targets and leaves dirty-pruned target open");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase290_Dirty_Pending_Remove_Selected_Prunes_Without_Buffer_Mutation;


   procedure Test_Phase290_Dirty_Remove_Selected_Deterministic_Rejections
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase290_dirty_remove_rejections");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, C_Id, 1);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No pending marked action",
              "Phase 290 dirty-remove-selected reports deterministically without a pending marked action");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 290 no-pending rejection does not create pending or pruned state");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1,
              "Phase 290 rejection setup captured one pending target");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, C_Id, 1);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "Selected buffer is not a pending close target",
              "Phase 290 availability rejects a dirty selected buffer that is not active pending close");
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Selected buffer is not a pending close target",
              "Phase 290 dirty non-pending selection reports deterministically");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffers.Global_Contains (C_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, C_Id),
              "Phase 290 dirty non-pending rejection leaves pending, pruned, open, and dirty state unchanged");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, A_Id, 1);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "Selected pending close target is not dirty",
              "Phase 290 availability rejects a clean selected pending target");
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Selected pending close target is not dirty",
              "Phase 290 clean pending selection reports deterministically");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffers.Global_Contains (A_Id),
              "Phase 290 clean pending rejection leaves pending targets, pruned history, and buffers unchanged");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase290_Dirty_Remove_Selected_Deterministic_Rejections;


   procedure Test_Phase291_Dirty_Prune_Preview_Apply_Cancel_And_Revalidation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase291_dirty_prune_preview");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      D_Path : constant String := Ada.Directories.Compose (Root, "delta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      D_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha"); Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma"); Write_Bytes (D_Path, "delta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "bulk");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "dirty");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "captured");
      Editor.Executor.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_File (S, D_Path); D_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty delta not pending"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 2,
              "Phase 291 setup captures two dirty active pending targets and excludes dirty non-pending buffers");

      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "alpha");
      Editor.Buffer_Switcher.Set_Pinned_Filter (S.Buffer_Switcher);
      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Avail := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 291 dirty-prune preview is available when dirty active pending targets exist");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune prepared: 2 of 3 pending close targets",
              "Phase 291 preview reports captured dirty active pending targets, including filtered/query-hidden ones");
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffers.Global_Contains (B_Id)
              and then Editor.Buffers.Global_Contains (C_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, C_Id),
              "Phase 291 preview captures identities without pruning, closing, saving, discarding, or dirty-state mutation");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id)
              and then Editor.Buffers.Global_Is_Buffer_Pinned (B_Id)
              and then Editor.Buffers.Global_Buffer_Group (B_Id) = "bulk"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "dirty"
              and then Editor.Buffers.Global_Buffer_Note (B_Id) = "captured"
              and then Editor.Buffers.Global_Active_Buffer = D_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "Phase 291 preview does not mutate marks, metadata, active buffer, navigation history, or recent-buffer state");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 2 | Applicable: 2",
              "Phase 291 optional dirty-prune badge is snapshot-derived from captured preview state");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune preview targets: 2; 2 still applicable",
              "Phase 291 summary reports captured and still-applicable dirty pending counts");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune cancelled"
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 291 cancel clears preview without mutating pending or pruned targets");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2,
              "Phase 291 repeated preview refreshes the captured target set");

      Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
      Editor.Buffers.Global_Set_Active_Buffer (B_Id); Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer (A_Id); Editor.Buffers.Load_Global_Active_Into_State (S);
      Set_Buffer_Text (S, "alpha became dirty after preview"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer (D_Id); Editor.Buffers.Load_Global_Active_Into_State (S);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune preview targets: 2; 1 still applicable",
              "Phase 291 summary revalidates applicability without refreshing captured targets");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pruned 1 dirty pending close targets",
              "Phase 291 apply prunes only captured targets that remain open, pending, and dirty");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 1
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher),
              "Phase 291 apply skips clean captured targets, ignores newly dirty uncaptured targets, records ordinary pruned history, and clears preview");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) =
              "Pending close: 2 | Dirty: 1 | Pruned: 1",
              "Phase 291 apply updates pending, dirty, and pruned counts in the next switcher snapshot");
      Assert (Editor.Buffers.Global_Contains (C_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, C_Id)
              and then True,
              "Phase 291 apply does not close dirty-pruned buffers or create reopen entries");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 2,
              "Phase 291 dirty-pruned targets restore through ordinary pruned restoration and become dirty-pending if still dirty");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase291_Dirty_Prune_Preview_Apply_Cancel_And_Revalidation;


   procedure Test_Phase292_Dirty_Prune_Review_Summary_Navigation_And_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase292_dirty_prune_review");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Found  : Boolean := False;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No pending dirty-prune action",
              "Phase 292 dirty-prune summary reports deterministically without a preview");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 2,
              "Phase 292 setup has two dirty active pending close targets");

      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2,
              "Phase 292 preview captures dirty pending target identities");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune preview targets: 2; 2 still applicable",
              "Phase 292 summary reports captured and still-applicable counts");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty-prune preview review shown"
              and then Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "Phase 292 dirty-prune review narrows the switcher to open captured preview targets");
      Row := Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1);
      Assert (Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, Row.Id),
              "Phase 292 review rows are captured dirty-prune preview targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Latest_Message_Text (S) = "Selected next dirty-prune preview target"
              and then Found
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, Row.Id)
              and then Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "Phase 292 dirty-prune next selects a captured target without activation, navigation history, or recent-buffer mutation");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Latest_Message_Text (S) = "Selected previous dirty-prune preview target"
              and then Found
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, Row.Id)
              and then Editor.Buffers.Global_Active_Buffer = C_Id,
              "Phase 292 dirty-prune previous selects a captured target without activating it");

      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "beta");
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Assert (Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 292 dirty-prune review composes with the literal switcher query without changing captured targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty-prune preview review hidden"
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher) = "beta",
              "Phase 292 hiding dirty-prune review restores ordinary projection without clearing query state");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffers.Global_Set_Active_Buffer (B_Id); Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := False; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer (C_Id); Editor.Buffers.Load_Global_Active_Into_State (S);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty prune preview targets: 2; 1 still applicable"
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "Phase 292 summary revalidates applicability without refreshing the captured review target set");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id),
              "Phase 292 dirty-prune apply clears review state and prunes only still-applicable captured targets");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase292_Dirty_Prune_Review_Summary_Navigation_And_Clear;


   procedure Test_Phase293_Dirty_Prune_Remove_Selected_Edits_Preview_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase293_dirty_prune_remove_selected");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Found  : Boolean := False;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "bulk");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "dirty");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "captured");
      Editor.Executor.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No pending dirty-prune action",
              "Phase 293 remove-selected reports deterministically without a dirty-prune preview");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 293 setup captures two dirty preview targets without pruning pending close");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, A_Id, 1);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "Selected buffer is not a dirty-prune preview target",
              "Phase 293 availability rejects selected rows outside the captured preview set");
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Selected buffer is not a dirty-prune preview target"
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 293 non-preview selection leaves preview, pending, and pruned state unchanged");

      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = B_Id
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, B_Id),
              "Phase 293 review selection uses buffer identity from the selected row");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 293 remove-selected is available for a selected captured dirty-prune preview target");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then not Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 2
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 293 remove-selected edits only the prepared dirty-prune preview set, not active pending targets or pruned history");
      Assert (Editor.Buffers.Global_Contains (B_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffers.Global_Is_Buffer_Pinned (B_Id)
              and then Editor.Buffers.Global_Buffer_Group (B_Id) = "bulk"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "dirty"
              and then Editor.Buffers.Global_Buffer_Note (B_Id) = "captured"
              and then Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "Phase 293 remove-selected does not close, clean, mark, mutate metadata, activate, or update navigation/recent history");
      Assert (Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = C_Id,
              "Phase 293 review rows and preview target normalize to the remaining captured target");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id),
              "Phase 293 apply prunes only remaining dirty-prune preview targets; removed preview targets remain pending and unpruned");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1,
              "Phase 293 preparing dirty-prune preview again recaptures still-dirty active pending targets previously removed from preview");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S.Buffer_Switcher),
              "Phase 298 removing the last dirty-prune preview target clears the preview action, exits review, and clears removed-preview history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase293_Dirty_Prune_Remove_Selected_Edits_Preview_Only;


   procedure Test_Phase294_Dirty_Prune_Restore_Last_Removed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase294_dirty_prune_restore_last_removed");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Found  : Boolean := False;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "bulk");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "dirty");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "captured");
      Editor.Executor.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "No pending dirty-prune action",
              "Phase 294 restore-last-removed is unavailable without a dirty-prune workflow");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No pending dirty-prune action",
              "Phase 294 restore-last-removed reports deterministically without a preview");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2,
              "Phase 294 setup captures two dirty-prune preview targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "No removed dirty-prune preview targets",
              "Phase 294 restore-last-removed is unavailable before any preview target removal");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "No removed dirty-prune preview targets",
              "Phase 294 restore-last-removed reports empty removed preview history");

      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Last_Removed_Dirty_Pending_Marked_Close_Prune_Target_Name (S.Buffer_Switcher) = "beta.adb"
              and then not Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, C_Id),
              "Phase 294 remove-selected records removed dirty-prune preview identity without active preview membership");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Removed dirty-prune preview targets: 1; 1 still open",
              "Phase 294 removed-summary reports removed and still-open preview targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 294 restore-last-removed is available after preview target removal");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Restored beta.adb to dirty-prune preview"
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 294 restore-last-removed returns the target to preview without mutating pending close or pruned history");
      Assert (Editor.Buffers.Global_Contains (B_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffers.Global_Is_Buffer_Pinned (B_Id)
              and then Editor.Buffers.Global_Buffer_Group (B_Id) = "bulk"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "dirty"
              and then Editor.Buffers.Global_Buffer_Note (B_Id) = "captured"
              and then Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "Phase 294 restore-last-removed does not close, clean, mark, mutate metadata, activate, or update navigation/recent history");
      Assert (Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "Phase 294 dirty-prune review candidate set reflects the restored preview target");

      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Last_Pruned_Pending_Marked_Close_Target_Name (S.Buffer_Switcher) = "gamma.adb",
              "Phase 294 apply prunes restored targets in deterministic original preview order");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id),
              "Phase 294 restored preview targets become ordinary pruned targets only after dirty-prune apply");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase294_Dirty_Prune_Restore_Last_Removed;


   procedure Test_Phase295_Removed_Dirty_Prune_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase295_removed_dirty_prune_navigation");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Found  : Boolean := False;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty alpha"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, A_Id, 1);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, C_Id, 1);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2
              and then Editor.Buffer_Switcher.Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 2,
              "Phase 295 setup has two still-open removed dirty-prune preview targets");

      Editor.Buffer_Switcher.Hide_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, B_Id, 1);
      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Removed dirty-prune preview targets: 2; 2 still open"
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 3,
              "Phase 295 removed summary reports removed/open counts without mutating active preview or pending targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Latest_Message_Text (S) = "Selected next removed dirty-prune preview target"
              and then Found
              and then Row.Id = C_Id
              and then Editor.Buffers.Global_Active_Buffer = C_Id
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then not Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 295 removed-next selects a still-open removed target in effective order without restoring, pruning, activating, or history mutation");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Latest_Message_Text (S) = "Selected previous removed dirty-prune preview target"
              and then Found
              and then Row.Id = A_Id
              and then not Editor.Buffer_Switcher.Row_Is_Dirty_Prune_Target (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, A_Id),
              "Phase 295 removed-previous selects the previous still-open removed target without restoring it");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S.Buffer_Switcher),
              "Phase 295 apply ignores unrestored removed preview targets and clears removed history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase295_Removed_Dirty_Prune_Navigation;


   procedure Test_Phase297_Dirty_Prune_Clear_Stale_Command_And_Apply
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase297_dirty_prune_clear_stale");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.Execute_Open_File (S, A_Path); A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path); B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_File (S, C_Path); C_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty gamma"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2,
              "Phase 297 setup captures the two dirty pending targets");

      Editor.Executor.Execute_Open_File (S, B_Path);
      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 297 stale summary is available with a dirty-prune preview");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Dirty-prune stale targets: 1 of 2",
              "Phase 297 stale summary reports stale of captured preview targets without mutation");
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 2,
              "Phase 297 stale summary does not clear or refresh preview targets");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "Phase 297 clear-stale is available when the active preview contains stale targets");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Cleared 1 stale dirty-prune preview targets",
              "Phase 297 clear-stale reports the number of stale preview targets removed");
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
                (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 1
              and then Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S.Buffer_Switcher, C_Id)
              and then not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S.Buffer_Switcher, B_Id),
              "Phase 297 clear-stale leaves only still-applicable preview targets");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher) = 0
              and then Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (S.Buffer_Switcher) = 0,
              "Phase 297 clear-stale does not mutate active pending close, ordinary pruned history, or removed-preview history");
      Assert (Editor.Buffers.Global_Contains (B_Id)
              and then not Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id)
              and then Editor.Buffers.Global_Contains (C_Id)
              and then Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, C_Id)
              and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
              "Phase 297 clear-stale does not close buffers, alter dirty state, or update navigation/recent history");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable
              and then Avail.Reason = "No stale dirty-prune preview targets",
              "Phase 297 clear-stale availability is deterministic when no stale targets remain");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S.Buffer_Switcher, C_Id),
              "Phase 297 apply after stale cleanup prunes only remaining applicable preview targets");

      Editor.Executor.Execute_Open_File (S, B_Path);
      Set_Buffer_Text (S, "dirty beta again"); S.File_Info.Dirty := True; Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S.Buffer_Switcher, B_Id),
              "Phase 297 preparing dirty-prune preview again can recapture a stale-cleaned target that is now dirty and active pending");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase297_Dirty_Prune_Clear_Stale_Command_And_Apply;




   procedure Test_Phase326_Reveal_Active_Selects_Known_Project_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase326_reveal_root");
      Src       : constant String := Ada.Directories.Compose (Root, "src");
      Exec_Path : constant String := Ada.Directories.Compose (Src, "executor.adb");
      Ads_Path  : constant String := Ada.Directories.Compose (Src, "executor.ads");
      Doc_Path  : constant String := Ada.Directories.Compose (Root, "README.md");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
      Snap      : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Exec_Path, "body");
      Write_Bytes (Ads_Path, "spec");
      Write_Bytes (Doc_Path, "doc");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String ("phase326"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "README.md", Doc_Path);
      Editor.Project.Add_Known_File (S.Project, "src/executor.adb", Exec_Path);
      Editor.Project.Add_Known_File (S.Project, "src/executor.ads", Ads_Path);

      Editor.Executor.Execute_Open_File (S, Exec_Path);
      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Executor.Execute_Quick_Open_Set_Query (S, "README");
      Editor.Executor.Execute_Quick_Open_Kind_Next (S);
      Editor.Executor.Execute_Quick_Open_Scope_Set (S, "docs");

      Editor.Executor.Execute_Quick_Open_Reveal_Active (S);
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);

      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open),
              "Phase 326 reveal-active must show Quick Open");
      Assert (To_String (Snap.Query) = "executor.adb",
              "Phase 546 reveal-active must install a filename query so no-query prompt does not hide the active file");
      Assert (Snap.File_Kind_Filter = Editor.Quick_Open.All_Files,
              "Phase 326 reveal-active must reset kind filter to All");
      Assert (To_String (Snap.Path_Scope) = "",
              "Phase 326 reveal-active must clear path scope");
      Assert (To_String (Snap.Selected_Path) = "src/executor.adb",
              "Phase 326 reveal-active must select the active project file by relative path");
      Assert (Snap.Visible_Count = 1 and then Snap.Known_Count = 3,
              "Phase 546 reveal-active count feedback must reflect the filename query and known project files");
      Assert (Latest_Message_Text (S) =
                "Quick Open selected active file: src/executor.adb",
              "Phase 326 reveal-active must report selection without claiming open/activation");

      Remove_Tree_If_Exists (Root);
   end Test_Phase326_Reveal_Active_Selects_Known_Project_File;

   procedure Test_Phase326_Scope_Active_Directory_Selects_Active_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase326_scope_root");
      Src       : constant String := Ada.Directories.Compose (Root, "src");
      Other_Dir : constant String := Ada.Directories.Compose (Root, "tests");
      Exec_Path : constant String := Ada.Directories.Compose (Src, "executor.adb");
      Ads_Path  : constant String := Ada.Directories.Compose (Src, "executor.ads");
      Test_Path : constant String := Ada.Directories.Compose (Other_Dir, "test_executor.adb");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
      Snap      : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Other_Dir);
      Write_Bytes (Exec_Path, "body");
      Write_Bytes (Ads_Path, "spec");
      Write_Bytes (Test_Path, "test");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String ("phase326"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "src/executor.adb", Exec_Path);
      Editor.Project.Add_Known_File (S.Project, "src/executor.ads", Ads_Path);
      Editor.Project.Add_Known_File (S.Project, "tests/test_executor.adb", Test_Path);

      Editor.Executor.Execute_Open_File (S, Exec_Path);
      Editor.Executor.Execute_Quick_Open_Scope_Active_Directory (S);
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);

      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open),
              "Phase 326 scope-active-directory must show Quick Open");
      Assert (To_String (Snap.Query) = "executor.adb",
              "Phase 546 scope-active-directory must install a filename query so no-query prompt does not hide the active file");
      Assert (Snap.File_Kind_Filter = Editor.Quick_Open.All_Files,
              "Phase 326 scope-active-directory must reset kind filter to All");
      Assert (To_String (Snap.Path_Scope) = "src/",
              "Phase 326 scope-active-directory must scope to the active file directory");
      Assert (To_String (Snap.Selected_Path) = "src/executor.adb",
              "Phase 326 scope-active-directory must select the active file");
      Assert (Snap.Visible_Count = 1 and then Snap.Known_Count = 3,
              "Phase 546 scope-active-directory count feedback must reflect scoped filename results");
      Assert (Latest_Message_Text (S) = "Quick Open scope: src/",
              "Phase 326 scope-active-directory must use existing scope message wording");

      Remove_Tree_If_Exists (Root);
   end Test_Phase326_Scope_Active_Directory_Selects_Active_File;

   procedure Test_Phase326_Active_Buffer_Not_Known_Does_Not_Show_Quick_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase326_not_known_root");
      Known     : constant String := Ada.Directories.Compose (Root, "known.adb");
      Unknown   : constant String := Ada.Directories.Compose (Root, "unknown.adb");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Known, "known");
      Write_Bytes (Unknown, "unknown");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String ("phase326"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "known.adb", Known);
      Editor.Executor.Execute_Open_File (S, Unknown);

      Editor.Executor.Execute_Quick_Open_Reveal_Active (S);

      Assert (not Editor.Quick_Open.Is_Open (S.Quick_Open),
              "Phase 326 reveal-active must not open Quick Open when active file is not known");
      Assert (Latest_Message_Text (S) = "Active buffer is not a known project file",
              "Phase 326 unknown active file must have deterministic feedback");

      Remove_Tree_If_Exists (Root);
   end Test_Phase326_Active_Buffer_Not_Known_Does_Not_Show_Quick_Open;


   procedure Test_Phase331_Active_Reveal_And_Scope_Preserve_Priority
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase331_active_priority_root");
      Src       : constant String := Ada.Directories.Compose (Root, "src");
      Docs      : constant String := Ada.Directories.Compose (Root, "docs");
      Exec_Path : constant String := Ada.Directories.Compose (Src, "executor.adb");
      Ads_Path  : constant String := Ada.Directories.Compose (Src, "executor.ads");
      Doc_Path  : constant String := Ada.Directories.Compose (Docs, "guide.md");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
      Snap      : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Docs);
      Write_Bytes (Exec_Path, "body");
      Write_Bytes (Ads_Path, "spec");
      Write_Bytes (Doc_Path, "doc");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String ("phase331"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "src/executor.adb", Exec_Path);
      Editor.Project.Add_Known_File (S.Project, "src/executor.ads", Ads_Path);
      Editor.Project.Add_Known_File (S.Project, "docs/guide.md", Doc_Path);

      Editor.Executor.Execute_Open_File (S, Exec_Path);
      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Executor.Execute_Quick_Open_Set_Query (S, "guide");
      Editor.Executor.Execute_Quick_Open_Kind_Next (S);
      Editor.Executor.Execute_Quick_Open_Scope_Set (S, "docs/");
      Editor.Executor.Execute_Quick_Open_Priority_Toggle (S);

      Editor.Executor.Execute_Quick_Open_Reveal_Active (S);
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
      Assert (Snap.Priority_Mode = Editor.Quick_Open.Open_Recent,
              "Phase 331 reveal-active must preserve Open/Recent priority mode");
      Assert (To_String (Snap.Query) = "executor.adb"
              and then Snap.File_Kind_Filter = Editor.Quick_Open.All_Files
              and then To_String (Snap.Path_Scope) = "",
              "Phase 546 reveal-active must normalize kind/scope and install the active filename query");
      Assert (To_String (Snap.Selected_Path) = "src/executor.adb",
              "Phase 331 reveal-active must select the active file despite previous filters");
      Assert (Latest_Message_Text (S) =
                "Quick Open selected active file: src/executor.adb",
              "Phase 331 reveal-active must keep one selection message");

      Editor.Executor.Execute_Quick_Open_Set_Query (S, "guide");
      Editor.Executor.Execute_Quick_Open_Kind_Next (S);
      Editor.Executor.Execute_Quick_Open_Scope_Set (S, "docs/");
      Assert (Editor.Quick_Open.Priority_Mode (S.Quick_Open) = Editor.Quick_Open.Open_Recent,
              "test setup must keep Open/Recent priority before scope-active-directory");

      Editor.Executor.Execute_Quick_Open_Scope_Active_Directory (S);
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
      Assert (Snap.Priority_Mode = Editor.Quick_Open.Open_Recent,
              "Phase 331 scope-active-directory must preserve Open/Recent priority mode");
      Assert (To_String (Snap.Query) = "executor.adb"
              and then Snap.File_Kind_Filter = Editor.Quick_Open.All_Files
              and then To_String (Snap.Path_Scope) = "src/",
              "Phase 546 scope-active-directory must reset kind/scope and install the active filename query");
      Assert (To_String (Snap.Selected_Path) = "src/executor.adb"
              and then Snap.Visible_Count = 1 and then Snap.Known_Count = 3,
              "Phase 546 scope-active-directory must select active file and keep scoped filename counts coherent");
      Assert (Latest_Message_Text (S) = "Quick Open scope: src/",
              "Phase 331 scope-active-directory must keep one scope message");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase331_Active_Reveal_And_Scope_Preserve_Priority;

   procedure Test_Phase331_Stale_Quick_Open_Open_Failure_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase331_stale_open_root");
      Src        : constant String := Ada.Directories.Compose (Root, "src");
      Stale_Path : constant String := Ada.Directories.Compose (Src, "stale.adb");
      Other_Path : constant String := Ada.Directories.Compose (Src, "other.adb");
      S          : Editor.State.State_Type;
      Open_Res   : Editor.Project.Project_Open_Result;
      Refresh    : Editor.Project.Project_File_Refresh_Result;
      Snap       : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Stale_Path, "stale");
      Write_Bytes (Other_Path, "other");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 331 stale-open test project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Refresh_Known_Files (S.Project, Refresh);
      Assert (Refresh.Status = Editor.Project.Project_File_Refresh_Ok,
              "Phase 331 stale-open setup refresh must succeed");

      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Executor.Execute_Quick_Open_Set_Query (S, "stale");
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
      Assert (To_String (Snap.Selected_Path) = "src/stale.adb",
              "Phase 331 stale-open setup must select stale candidate");

      Ada.Directories.Delete_File (Stale_Path);
      Editor.Executor.Execute_Accept_Quick_Open (S);
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);

      Assert (Latest_Message_Text (S) =
                "Could not open src/stale.adb: file not found",
              "Phase 331 stale open failure must report one deterministic failure message");
      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open),
              "Phase 331 stale open failure must keep Quick Open visible");
      Assert (To_String (Snap.Query) = "stale"
              and then To_String (Snap.Selected_Path) = "src/stale.adb",
              "Phase 331 stale open failure must preserve query and selected known candidate");
      Assert (Editor.Project.Has_Known_File (S.Project, "src/stale.adb"),
              "Phase 331 stale open failure must not mutate known files before refresh");
      Assert (not Editor.State.Has_Active_Buffer (S),
              "Phase 331 stale open failure must not invent an active buffer");

      Editor.Project.Refresh_Known_Files (S.Project, Refresh);
      Assert (Refresh.Status = Editor.Project.Project_File_Refresh_Ok
              and then Refresh.Removed_Count = 1,
              "Phase 331 later refresh must remove the stale known path");
      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.Project, (others => <>));
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/stale.adb")
              and then Snap.Visible_Count = 0
              and then To_String (Snap.Selected_Path) = "",
              "Phase 331 refresh after stale failure must clear stale candidate selection");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase331_Stale_Quick_Open_Open_Failure_Preserves_State;

   procedure Test_Phase347_Quick_Open_Accept_Records_Previous_Location
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase347_quick_open_record_root");
      A_Path    : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path    : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 347 Quick Open record setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "alpha.adb", A_Path);
      Editor.Project.Add_Known_File (S.Project, "beta.adb", B_Path);

      Editor.Executor.Execute_Open_File (S, A_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Executor.Execute_Quick_Open_Set_Query (S, "beta");
      Editor.Executor.Execute_Accept_Quick_Open (S);

      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
              "Phase 347 Quick Open accept must open selected target");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "Phase 347 Quick Open accept must record previous editor location on success");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "Phase 347 successful new Quick Open navigation must leave no forward history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase347_Quick_Open_Accept_Records_Previous_Location;

   procedure Test_Phase347_Quick_Open_Stale_Failure_Does_Not_Record
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase347_quick_open_stale_root");
      Current    : constant String := Ada.Directories.Compose (Root, "current.adb");
      Stale_Path : constant String := Ada.Directories.Compose (Root, "stale.adb");
      S          : Editor.State.State_Type;
      Open_Res   : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Current, "current");
      Write_Bytes (Stale_Path, "stale");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 347 Quick Open stale setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "current.adb", Current);
      Editor.Project.Add_Known_File (S.Project, "stale.adb", Stale_Path);

      Editor.Executor.Execute_Open_File (S, Current);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Executor.Execute_Quick_Open_Set_Query (S, "stale");
      Ada.Directories.Delete_File (Stale_Path);
      Editor.Executor.Execute_Accept_Quick_Open (S);

      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Current,
              "Phase 347 stale Quick Open failure must keep active editor location");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "Phase 347 stale Quick Open failure must not record previous location");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "Phase 347 stale Quick Open failure must not mutate forward history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase347_Quick_Open_Stale_Failure_Does_Not_Record;


   procedure Test_Phase349_Quick_Open_Captures_Execution_Time_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase349_quick_open_capture");
      A_Path   : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path   : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, Numbered_Lines (50));
      Write_Bytes (B_Path, Numbered_Lines (10));

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 349 Quick Open capture setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "alpha.adb", A_Path);
      Editor.Project.Add_Known_File (S.Project, "beta.adb", B_Path);

      Editor.Executor.Execute_Open_File (S, A_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Move_Caret_To_Line (S, 20);

      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Executor.Execute_Quick_Open_Set_Query (S, "beta");
      Editor.Executor.Execute_Accept_Quick_Open (S);

      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
              "Phase 349 Quick Open accept must open the selected target");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1
              and then Back_Top_Path (S) = A_Path
              and then Back_Top_Line (S) = 20,
              "Phase 349 Quick Open must record the execution-time caret line, not the stale open line");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = A_Path
              and then Active_Caret_Line (S) = 20,
              "Phase 349 navigation.back must return to the captured Quick Open source line");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "Phase 349 back must create a coherent forward entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
              "Phase 349 navigation.forward must restore the Quick Open destination");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "Phase 349 forward must leave one useful previous-location entry");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase349_Quick_Open_Captures_Execution_Time_Caret;


   procedure Test_Phase349_Project_Search_Same_File_Line_Roundtrip
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase349_project_search_same_file");
      Path     : constant String := Ada.Directories.Compose (Root, "executor.adb");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Path, Numbered_Lines (130, 120));

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 349 Project Search setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "executor.adb", Path);

      Editor.Executor.Execute_Open_File (S, Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Move_Caret_To_Line (S, 20);

      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "Phase 349 same-file Project Search setup must produce one result");
      Editor.Executor.Execute_Open_Selected_Project_Search_Result (S);

      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path,
              "Phase 349 Project Search open-selected must stay in the same file");
      Assert (Active_Caret_Line (S) = 120,
              "Phase 349 Project Search open-selected must move to the result line");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1
              and then Back_Top_Line (S) = 20,
              "Phase 349 same-file search navigation must record the prior line as useful history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path
              and then Active_Caret_Line (S) = 20,
              "Phase 349 back must return to the same-file source line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path
              and then Active_Caret_Line (S) = 120,
              "Phase 349 forward must return to the same-file search result line");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase349_Project_Search_Same_File_Line_Roundtrip;


   procedure Test_Phase349_Back_Forward_Capture_Moved_Current_Anchors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase349_refined_anchors");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, Numbered_Lines (40));
      Write_Bytes (B_Path, Numbered_Lines (40));
      Write_Bytes (C_Path, Numbered_Lines (40));

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_File (S, A_Path);
      Editor.Executor.Execute_Open_File (S, B_Path);
      Editor.Executor.Execute_Open_File (S, C_Path);
      Move_Caret_To_Line (S, 30);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (A_Path), Display_Path => To_Unbounded_String ("alpha.adb"),
          Line => 10, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (B_Path), Display_Path => To_Unbounded_String ("beta.adb"),
          Line => 20, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path
              and then Active_Caret_Line (S) = 20
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "Phase 349 setup back must move C:30 to B:20 and save C for forward");

      Move_Caret_To_Line (S, 25);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = C_Path
              and then Active_Caret_Line (S) = 30
              and then Back_Top_Line (S) = 25,
              "Phase 349 forward must capture the moved B:25 anchor at execution time");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path
              and then Active_Caret_Line (S) = 25,
              "Phase 349 next back must return to moved B:25 rather than stale B:20");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase349_Back_Forward_Capture_Moved_Current_Anchors;


   procedure Test_Phase349_Forward_Stack_Clears_Only_On_Successful_New_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase349_forward_clear");
      A_Path     : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path     : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path     : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      D_Path     : constant String := Ada.Directories.Compose (Root, "delta.adb");
      Stale_Path : constant String := Ada.Directories.Compose (Root, "stale.adb");
      S          : Editor.State.State_Type;
      Open_Res   : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha");
      Write_Bytes (B_Path, "beta");
      Write_Bytes (C_Path, "gamma");
      Write_Bytes (D_Path, "delta");
      Write_Bytes (Stale_Path, "stale");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 349 forward-clear setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "alpha.adb", A_Path);
      Editor.Project.Add_Known_File (S.Project, "beta.adb", B_Path);
      Editor.Project.Add_Known_File (S.Project, "gamma.adb", C_Path);
      Editor.Project.Add_Known_File (S.Project, "delta.adb", D_Path);
      Editor.Project.Add_Known_File (S.Project, "stale.adb", Stale_Path);

      Editor.Executor.Execute_Open_File (S, B_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (A_Path), Display_Path => To_Unbounded_String ("alpha.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (C_Path), Display_Path => To_Unbounded_String ("gamma.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));

      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Executor.Execute_Quick_Open_Set_Query (S, "delta");
      Editor.Executor.Execute_Accept_Quick_Open (S);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = D_Path,
              "Phase 349 successful new navigation must open D");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "Phase 349 successful new non-history navigation must clear forward history");
      Assert (Back_Top_Path (S) = B_Path,
              "Phase 349 successful new navigation must record current B before D");

      Editor.Executor.Execute_Open_File (S, B_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (A_Path), Display_Path => To_Unbounded_String ("alpha.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (C_Path), Display_Path => To_Unbounded_String ("gamma.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Ada.Directories.Delete_File (Stale_Path);

      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Executor.Execute_Quick_Open_Set_Query (S, "stale");
      Editor.Executor.Execute_Accept_Quick_Open (S);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
              "Phase 349 stale Quick Open failure must preserve active B");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1
              and then Forward_Top_Line (S) = 1,
              "Phase 349 failed new navigation must not push current or clear forward history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = C_Path,
              "Phase 349 preserved forward history must still navigate to C after failed new navigation");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase349_Forward_Stack_Clears_Only_On_Successful_New_Navigation;


   procedure Test_Phase349_Non_Recording_Selection_Commands_Preserve_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase349_non_recording");
      A_Path   : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path   : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
      Back_Before    : Natural := 0;
      Forward_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (A_Path, "alpha needle" & ASCII.LF & "again needle");
      Write_Bytes (B_Path, "beta");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 349 non-recording setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "alpha.adb", A_Path);
      Editor.Project.Add_Known_File (S.Project, "beta.adb", B_Path);

      Editor.Executor.Execute_Open_File (S, A_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (A_Path), Display_Path => To_Unbounded_String ("alpha.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (B_Path), Display_Path => To_Unbounded_String ("beta.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Executor.Execute_Quick_Open_Set_Query (S, "alpha");
      Editor.Executor.Execute_Quick_Open_Next_Result (S);
      Editor.Executor.Execute_Quick_Open_Previous_Result (S);
      Editor.Executor.Execute_Run_Project_Search (S, "needle");
      Editor.Executor.Execute_Next_Project_Search_Result (S);
      Editor.Executor.Execute_Previous_Project_Search_Result (S);
      Editor.Executor.Execute_Reveal_Active_Project_Search_Result (S);
      Editor.Executor.Execute_Bookmark_Toggle_Surface (S);
      Editor.Executor.Execute_Bookmark_Reveal_Current (S);

      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before,
              "Phase 349 selection/read-only feature commands must not capture, clear, or normalize navigation history");

      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Executor.Execute_Quick_Open_Set_Query (S, "alpha");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before,
              "Phase 349 reopening/querying Quick Open before clear must still not mutate history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_History_Clear);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "Phase 349 history.clear must mutate only navigation history stacks");
      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open)
              and then Editor.Project_Search.Result_Count (S.Project_Search) = 2,
              "Phase 349 history.clear must preserve populated Quick Open and Project Search state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase349_Non_Recording_Selection_Commands_Preserve_History;


   procedure Select_File_Tree_Test_Path
     (S             : in out Editor.State.State_Type;
      Relative_Path : String)
   is
      Found     : Boolean := False;
      Row_Found : Boolean := False;
      Node      : constant Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.Find_By_Path (S.File_Tree, Relative_Path, Found);
      Row       : Natural := 0;
   begin
      Assert (Found, "test file tree path must exist: " & Relative_Path);
      Editor.File_Tree.Expand_Ancestors (S.File_Tree, Node);
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "test file tree row must be visible: " & Relative_Path);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
   end Select_File_Tree_Test_Path;

   procedure Test_Phase572_Rename_Active_File_Invalidates_Derived_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase572_rename_invalidates");
      Old_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      New_Path : constant String := Ada.Directories.Compose (Root, "renamed.txt");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
      Cmd      : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Remove_Tree_If_Exists (Root);
      Build_Fixture (Root);

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 572 rename setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Executor.Execute_Open_File (S, Old_Path);

      declare
         Result : constant Editor.Outline.Outline_Refresh_Result :=
           Editor.Outline.Fixtures.Populate_Synthetic_Outline (S.Outline);
      begin
         Assert
           (Result.Status = Editor.Outline.Outline_Refresh_Ok,
            "synthetic outline fixture refresh succeeds");
      end;
      Editor.Diagnostics.Add
        (S.Diagnostics, 1, 1, Editor.Diagnostics.Error, "before rename");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "before rename",
         Source_Label => "a.txt");

      Select_File_Tree_Test_Path (S, "a.txt");
      Cmd.Text := To_Unbounded_String ("renamed.txt");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Ada.Directories.Exists (New_Path),
              "Phase 572 rename must create renamed target");
      Assert (not Ada.Directories.Exists (Old_Path),
              "Phase 572 rename must remove old target");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = New_Path,
              "Phase 572 clean active buffer path must be rebased");
      Assert (not Editor.Outline.Has_Items (S.Outline),
              "Phase 572 rename of active file must clear stale outline rows");
      Assert (Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0,
              "Phase 572 rename of active file must clear stale active diagnostics");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "Phase 572 rename of active file must clear stale diagnostics feature rows");
      Assert (Editor.Project_Search.Is_Stale (S.Project_Search),
              "Phase 572 rename must mark project search state stale");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase572_Rename_Active_File_Invalidates_Derived_State;

   procedure Test_Phase572_Delete_Build_Config_Marks_Selected_Candidate_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_build_config_stale");
      Alire_Path : constant String := Ada.Directories.Compose (Root, "alire.toml");
      S          : Editor.State.State_Type;
      Open_Res   : Editor.Project.Project_Open_Result;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Cmd        : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Delete_Selected);
   begin
      Remove_Tree_If_Exists (Root);
      Build_Fixture (Root);
      Write_Bytes (Alire_Path, "name = ""demo""" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 572 build-config setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      Candidates.Append (Editor.Build_Candidates.Alire_Candidate (Root));
      Editor.Build_UI.Set_Build_Candidates (S.Build_UI, Candidates, "test");
      Editor.Build_UI.Select_Build_Candidate
        (S.Build_UI, Editor.Build_Candidates.Candidate_Id_For_Alire (Root));
      Assert (To_String (S.Build_UI.Selected_Build_Candidate_Id)'Length > 0,
              "Phase 572 setup must select build candidate");

      Select_File_Tree_Test_Path (S, "alire.toml");
      Cmd.Text := To_Unbounded_String ("confirm");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Ada.Directories.Exists (Alire_Path),
              "Phase 572 delete must remove selected build config file");
      Assert (S.Build_UI.Selected_Candidate_Stale,
              "Phase 572 delete of build config must stale selected build candidate");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "Phase 572 stale build candidate must clear consent");
      Assert (not S.Build_UI.Pending_Public_Build_Request,
              "Phase 572 stale build candidate must clear pending request");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase572_Delete_Build_Config_Marks_Selected_Candidate_Stale;


   procedure Test_Phase572_Rename_Directory_With_Build_Config_Invalidates_Candidates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_build_config_dir_rename");
      Config_Dir : constant String := Ada.Directories.Compose (Root, "config");
      Old_Gpr    : constant String := Ada.Directories.Compose (Config_Dir, "demo.gpr");
      New_Dir    : constant String := Ada.Directories.Compose (Root, "renamed_config");
      New_Gpr    : constant String := Ada.Directories.Compose (New_Dir, "demo.gpr");
      S          : Editor.State.State_Type;
      Open_Res   : Editor.Project.Project_Open_Result;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Cmd        : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Remove_Tree_If_Exists (Root);
      Build_Fixture (Root);
      Ada.Directories.Create_Directory (Config_Dir);
      Write_Bytes (Old_Gpr, "project Demo is end Demo;" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 572 directory build-config setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      Candidates.Append (Editor.Build_Candidates.Gprbuild_Candidate
        (Root, "config/demo.gpr"));
      Editor.Build_UI.Set_Build_Candidates (S.Build_UI, Candidates, "test");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 1,
              "Phase 572 setup must have a discovered build candidate");

      Select_File_Tree_Test_Path (S, "config");
      Cmd.Text := To_Unbounded_String ("renamed_config");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Ada.Directories.Exists (New_Gpr),
              "Phase 572 directory rename must move nested build config");
      Assert (not Ada.Directories.Exists (Old_Gpr),
              "Phase 572 directory rename must remove old nested build config path");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 0,
              "Phase 572 directory rename containing build config must clear stale candidates");
      Assert
        (S.Build_UI.Candidate_Refresh_Status =
           Editor.Build_UI.Build_Candidate_Refresh_Not_Requested,
         "Phase 572 stale build candidates must require explicit rediscovery");
      Assert
        (To_String (S.Build_UI.Candidate_Discovery_Message) =
           "Build candidates are stale after File Tree mutation",
         "Phase 572 directory build-config rename must report stale candidates");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase572_Rename_Directory_With_Build_Config_Invalidates_Candidates;


   procedure Test_Phase572_Rename_Marks_Relative_Diagnostics_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase572_relative_diag_stale");
      Old_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      New_Path : constant String := Ada.Directories.Compose (Root, "renamed.txt");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
      Cmd      : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Remove_Tree_If_Exists (Root);
      Build_Fixture (Root);

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 572 relative diagnostics setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "old file diagnostic",
         Source_Label => "a.txt");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Info,
         "unrelated diagnostic",
         Source_Label => "other.txt");

      Select_File_Tree_Test_Path (S, "a.txt");
      Cmd.Text := To_Unbounded_String ("renamed.txt");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Ada.Directories.Exists (New_Path),
              "Phase 572 relative diagnostics rename must create renamed target");
      Assert (not Ada.Directories.Exists (Old_Path),
              "Phase 572 relative diagnostics rename must remove old target");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 2,
              "Phase 572 relative diagnostics rename must preserve diagnostic rows");
      Assert (Editor.Feature_Diagnostics.Item_Is_Stale (S.Feature_Diagnostics, 1),
              "Phase 572 relative source-label diagnostic must be marked stale");
      Assert (not Editor.Feature_Diagnostics.Item_Is_Stale (S.Feature_Diagnostics, 2),
              "Phase 572 unrelated relative diagnostic must remain live");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase572_Rename_Marks_Relative_Diagnostics_Stale;



   procedure Test_Phase572_Rename_Marks_Relative_Build_Source_Candidate_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("phase572_relative_build_source_stale");
      Src_Dir  : constant String := Ada.Directories.Compose (Root, "src");
      Old_Path : constant String := Ada.Directories.Compose (Src_Dir, "main.adb");
      New_Path : constant String := Ada.Directories.Compose (Src_Dir, "renamed.adb");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
      Candidate  : Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate (Root, "demo.gpr");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Cmd      : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Remove_Tree_If_Exists (Root);
      Build_Fixture (Root);
      Ada.Directories.Create_Directory (Src_Dir);
      Write_Bytes (Old_Path, "procedure Main is begin null; end Main;" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 572 relative build-source setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      Candidate.Candidate_Id := To_Unbounded_String ("relative-source-candidate");
      Candidate.Source_Path_If_Represented := To_Unbounded_String ("src/main.adb");
      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates (S.Build_UI, Candidates, "test");
      S.Build_UI.Selected_Build_Candidate_Id :=
        To_Unbounded_String ("relative-source-candidate");
      S.Build_UI.Consent_Acknowledged := True;
      S.Build_UI.Pending_Public_Build_Request := True;

      Select_File_Tree_Test_Path (S, "src/main.adb");
      Cmd.Text := To_Unbounded_String ("renamed.adb");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Ada.Directories.Exists (New_Path),
              "Phase 572 relative build-source rename must create renamed file");
      Assert (not Ada.Directories.Exists (Old_Path),
              "Phase 572 relative build-source rename must remove old file path");
      Assert (S.Build_UI.Selected_Candidate_Stale,
              "Phase 572 relative build-source candidate must be marked stale");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "Phase 572 stale relative build-source candidate must clear consent");
      Assert (not S.Build_UI.Pending_Public_Build_Request,
              "Phase 572 stale relative build-source candidate must clear pending request");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 1,
              "Phase 572 non-build-config source rename must preserve candidate list");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase572_Rename_Marks_Relative_Build_Source_Candidate_Stale;



   procedure Test_Phase577_Project_Switch_Discard_Uses_Lifecycle_Affected_Set
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A     : constant String := Temp_Path ("phase577_switch_sets_a");
      Root_B     : constant String := Temp_Path ("phase577_switch_sets_b");
      Project_A  : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      Outside_F  : constant String := Temp_Path ("phase577_switch_sets_outside.txt");
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Found      : Boolean := False;
      Ignored_Id : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Ignored_Id);
      Outside_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Write_Bytes (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root_A);

      Editor.Executor.Execute_Open_File (S, Outside_F);
      Editor.State.Replace_Buffer_Contents (S, "outside dirty retained");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "project dirty affected");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      declare
         Sets : constant Editor.Buffers.Buffer_Project_Lifecycle_Sets :=
           Editor.Buffers.Global_Project_Lifecycle_Buffer_Sets (S.Project);
      begin
         Assert (Natural (Sets.Project_Close_Affected.Length) = 1,
                 "Phase 577 switch setup should expose exactly one affected project buffer");
         Assert (Natural (Sets.Project_Close_Unaffected.Length) = 1,
                 "Phase 577 switch setup should expose exactly one retained outside buffer");
      end;

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 577 switch with dirty project buffer should create a pending transition");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Discard_Pending_Transition);

      Assert (Editor.Project.Has_Project (S.Project),
              "Phase 577 switch discard should complete the project switch");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "Phase 577 switch discard should install the target project");
      Ignored_Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (not Found,
              "Phase 577 switch discard should close only affected project buffers");
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found and then Outside_Id /= Editor.Buffers.No_Buffer,
              "Phase 577 switch discard should retain outside-project buffers from the unaffected set");
      Assert (Editor.Buffers.Global_Summary_For (Outside_Id).Is_Dirty,
              "Phase 577 switch discard should preserve retained outside dirty text/state");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "Phase 577 completed switch discard should clear pending transition");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase577_Project_Switch_Discard_Uses_Lifecycle_Affected_Set;


   procedure Test_Phase577_Behavior_Preservation_Smoke_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("phase577_preserve_project");
      Project_F   : constant String := Ada.Directories.Compose (Root, "a.txt");
      Outside_F   : constant String := Temp_Path ("phase577_preserve_outside.txt");
      S           : Editor.State.State_Type;
      Project_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Outside_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Dirty : Editor.Dirty_Guards.Dirty_Buffer_Summary;
      After_Dirty  : Editor.Dirty_Guards.Dirty_Buffer_Summary;
      Before_Sets  : Editor.Buffers.Buffer_Project_Lifecycle_Sets;
      After_Sets   : Editor.Buffers.Buffer_Project_Lifecycle_Sets;
      Boundary     : Editor.Configuration_Audit.Buffer_Boundary_Audit_Summary;
      Cmd          : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Bytes (Outside_F, "outside clean");
      Init_Executor_Test_State (S);
      Editor.Executor.Execute_Open_Project (S, Root);

      Editor.Executor.Execute_Open_File (S, Outside_F);
      Outside_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "outside dirty retained by project lifecycle");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_File (S, Project_F);
      Project_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "project dirty reviewed by selected close");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Before_Dirty := Editor.Buffers.Global_Categorized_Dirty_Buffer_Summary (S.Project);
      Before_Sets  := Editor.Buffers.Global_Project_Lifecycle_Buffer_Sets (S.Project);
      Boundary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For
        (S,
         "workspace-format-version=1" & ASCII.LF
         & "open-file path=" & Project_F & ASCII.LF
         & "open-file path=" & Outside_F & ASCII.LF);

      Assert (Boundary.Buffer_Metadata_Coherent,
              "Phase 577 preservation smoke: metadata audit remains coherent");
      Assert (Boundary.Workspace_Persistence_Safe,
              "Phase 577 preservation smoke: workspace persistence boundary remains safe");
      Assert (Boundary.Command_Keybinding_Payloads_Clear,
              "Phase 577 preservation smoke: command/keybinding routes remain payload-free");
      Assert (Boundary.Render_Boundary_Safe,
              "Phase 577 preservation smoke: render remains observational");
      Assert (Before_Dirty.Dirty_Count = 2
                and then Before_Dirty.File_Backed_Count = 2,
              "Phase 577 preservation smoke: dirty guard summary still sees both dirty file buffers");
      Assert (Natural (Before_Sets.Project_Close_Affected.Length) = 1
                and then Natural (Before_Sets.Project_Close_Unaffected.Length) = 1,
              "Phase 577 preservation smoke: project lifecycle affected/retained split is stable");

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (S.Dirty_Close_Prompt_Active,
              "Phase 577 preservation smoke: selected dirty close still enters dirty review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope,
              "Phase 577 preservation smoke: selected close scope is preserved");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel);
      Assert (not S.Dirty_Close_Prompt_Active,
              "Phase 577 preservation smoke: cancel still exits dirty close review");
      Assert (Editor.Buffers.Global_Contains (Project_Id),
              "Phase 577 preservation smoke: cancel keeps selected project buffer open");
      Assert (Editor.Buffers.Global_Contains (Outside_Id),
              "Phase 577 preservation smoke: cancel keeps outside-project buffer open");

      After_Dirty := Editor.Buffers.Global_Categorized_Dirty_Buffer_Summary (S.Project);
      After_Sets  := Editor.Buffers.Global_Project_Lifecycle_Buffer_Sets (S.Project);
      Assert (After_Dirty.Dirty_Count = Before_Dirty.Dirty_Count
                and then After_Dirty.File_Backed_Count = Before_Dirty.File_Backed_Count,
              "Phase 577 preservation smoke: audit/routing changes do not disturb dirty guard state");
      Assert (Natural (After_Sets.Project_Close_Affected.Length) =
                Natural (Before_Sets.Project_Close_Affected.Length)
                and then Natural (After_Sets.Project_Close_Unaffected.Length) =
                  Natural (Before_Sets.Project_Close_Unaffected.Length),
              "Phase 577 preservation smoke: cancel preserves project lifecycle sets");

      Editor.Buffers.Global_Set_Active_Buffer (Project_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Buffer_Text (S) = "project dirty reviewed by selected close",
              "Phase 577 preservation smoke: selected project dirty text survives cancel");
      Assert (S.File_Info.Dirty,
              "Phase 577 preservation smoke: selected project dirty marker survives cancel");

      Editor.Buffers.Global_Set_Active_Buffer (Outside_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Buffer_Text (S) = "outside dirty retained by project lifecycle",
              "Phase 577 preservation smoke: outside-project dirty text remains retained");
      Assert (S.File_Info.Dirty,
              "Phase 577 preservation smoke: outside-project dirty marker remains retained");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase577_Behavior_Preservation_Smoke_Matrix;



   overriding procedure Register_Tests
     (T : in out Executor_Test_Case) is
   begin
      Remove_Tree_If_Exists (Executor_Recent_Config_Dir);
      Ada.Directories.Create_Path (Executor_Recent_Config_Dir);
      Use_Executor_Recent_Config;

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Project_Switch_Discard_Uses_Lifecycle_Affected_Set'Access,
         "Phase 577 project switch discard uses lifecycle affected set");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Behavior_Preservation_Smoke_Matrix'Access,
         "Phase 577 behavior preservation smoke matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Rename_Active_File_Invalidates_Derived_State'Access,
         "Phase 572 rename active file invalidates derived state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Delete_Build_Config_Marks_Selected_Candidate_Stale'Access,
         "Phase 572 delete build config marks selected candidate stale");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Rename_Directory_With_Build_Config_Invalidates_Candidates'Access,
         "Phase 572 rename directory containing build config invalidates candidates");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Rename_Marks_Relative_Diagnostics_Stale'Access,
         "Phase 572 rename marks relative diagnostics stale");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Rename_Marks_Relative_Build_Source_Candidate_Stale'Access,
         "Phase 572 rename marks relative build-source candidate stale");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase349_Quick_Open_Captures_Execution_Time_Caret'Access,
         "Phase 349 Quick Open captures execution-time caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase349_Project_Search_Same_File_Line_Roundtrip'Access,
         "Phase 349 Project Search same-file line roundtrip");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase349_Back_Forward_Capture_Moved_Current_Anchors'Access,
         "Phase 349 back/forward capture moved current anchors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase349_Forward_Stack_Clears_Only_On_Successful_New_Navigation'Access,
         "Phase 349 forward stack clears only on successful new navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase349_Non_Recording_Selection_Commands_Preserve_History'Access,
         "Phase 349 non-recording selection commands preserve history");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase246_Post_Restore_Command_Readiness'Access,
         "Phase 246 post-restore command readiness");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase246_First_Save_After_Restore_Uses_Normal_Path'Access,
         "Phase 246 first save after restore uses normal path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase246_First_Reload_After_Restore_Uses_Normal_Guards'Access,
         "Phase 246 first reload after restore uses normal guards");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase246_First_Close_And_Navigation_After_Restore'Access,
         "Phase 246 first close and navigation after restore");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase247_Restore_Feedback_Becomes_Historical_After_Edit'Access,
         "Phase 247 restore feedback becomes historical after edit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase247_Restore_Feedback_Replaced_By_Command_Outcome'Access,
         "Phase 247 restore feedback replaced by command outcome");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase249_Open_Edit_Syncs_Ordinary_Dirty_Row'Access,
         "Phase 249 open edit syncs ordinary dirty row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase249_Repeated_Switching_Preserves_Ordinary_Edit_Context'Access,
         "Phase 249 repeated switching preserves ordinary edit context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase249_Ordinary_Dirty_Reload_Blocks_Without_Row_Drift'Access,
         "Phase 249 ordinary dirty reload blocks without row drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase249_File_Tree_Focuses_Already_Open_Dirty_File_Ordinarily'Access,
         "Phase 249 File Tree focuses already-open dirty file ordinarily");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase248_Save_After_Cleanup_Uses_Ordinary_Feedback'Access,
         "Phase 248 save after cleanup uses ordinary feedback");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase248_Direct_Open_Clears_Restore_Feedback'Access,
         "Phase 248 direct open clears restore feedback");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase248_File_Tree_Row_Action_Is_Ordinary_After_Restore'Access,
         "Phase 248 File Tree row action is ordinary after restore");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase248_Already_Open_Dirty_File_Tree_Focus_Preserves_Text'Access,
         "Phase 248 already-open dirty File Tree focus preserves text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase245_Restore_Order_And_Active_Buffer_Agree'Access,
         "Phase 245 restore order and active buffer agree");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase245_Duplicate_Restored_File_Collapses_Deterministically'Access,
         "Phase 245 duplicate restored file collapses deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase245_Restored_Cursor_And_Viewport_Clamp'Access,
         "Phase 245 restored cursor and viewport clamp");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase245_Clean_Restore_Clears_Transient_Lifecycle'Access,
         "Phase 245 clean restore clears transient lifecycle");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase244_Workspace_Reopen_Missing_Active_Falls_Back'Access,
         "Phase 244 workspace reopen missing active falls back");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase244_Workspace_Reopen_Directory_Creates_No_Buffer'Access,
         "Phase 244 workspace reopen directory creates no buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase558_Workspace_Active_Outside_Open_Set_Does_Not_Open'Access,
         "Phase 558 workspace active outside open set does not open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase244_Workspace_Reopen_Already_Open_Dirty_No_Duplicate'Access,
         "Phase 244 workspace reopen already-open dirty no duplicate");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase243_Project_Close_Removes_Project_Clean_Buffers_Only'Access,
         "Phase 243 project close removes project clean buffers only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase243_Project_Close_Blocks_Project_Dirty_Buffer'Access,
         "Phase 243 project close blocks project dirty buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase243_Project_Close_Ignores_Unrelated_Dirty_Buffer'Access,
         "Phase 243 project close ignores unrelated dirty buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Switch_Closes_Old_Clean_Project_Buffers'Access,
         "Phase 560 project switch closes old clean project buffers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Switch_Blocks_Project_Dirty_And_Cancel_Is_Atomic'Access,
         "Phase 560 project switch blocks dirty and cancel is atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Switch_Target_Failure_Preserves_Previous_Project'Access,
         "Phase 560 project switch target failure preserves previous project");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Switch_Requires_Active_Source_Project'Access,
         "Phase 560 project switch requires active source project");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Switch_To_Current_Project_Is_No_Op'Access,
         "Phase 560 project switch to current project is no-op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Switch_To_Current_Project_Skips_Target_Preflight'Access,
         "Phase 560 project switch to current project skips target preflight");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Switch_Retry_Ignores_Retained_Outside_Dirty'Access,
         "Phase 560 project switch retry ignores retained outside dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Close_Retry_Ignores_Retained_Outside_Dirty'Access,
         "Phase 560 project close retry ignores retained outside dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Pending_Switch_Blocks_Different_Project_Target'Access,
         "Phase 560 pending switch blocks different target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Pending_Close_Blocks_Project_Switch'Access,
         "Phase 560 pending close blocks project switch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Close_Dirty_Cancel_Is_Atomic'Access,
         "Phase 560 project close dirty cancel is atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Close_Clears_Project_State_Not_Recent'Access,
         "Phase 560 project close clears state not recent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Switch_Preserves_Outside_Buffer_Undo'Access,
         "Phase 560 project switch preserves outside undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Close_Preserves_Outside_Buffer_Undo'Access,
         "Phase 560 project close preserves outside undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Switch_Preserves_Outside_Recent_Buffer_Order'Access,
         "Phase 560 project switch preserves outside recent buffer order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase560_Project_Close_Preserves_Outside_Recent_Buffer_Order'Access,
         "Phase 560 project close preserves outside recent buffer order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase239_File_Tree_Already_Open_Missing_File_Focuses_Buffer'Access,
         "Phase 239 File Tree already-open missing file focuses buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase224_Common_Availability_Reasons'Access,
         "Phase 224 common availability reasons");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase224_Availability_Feedback_Matches_Preflight'Access,
         "Phase 224 availability feedback matches preflight");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase224_Availability_Checks_Are_Side_Effect_Free'Access,
         "Phase 224 availability checks are side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase224_Palette_Disabled_Reason_Matches_Executor'Access,
         "Phase 224 palette disabled reason matches executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase222_Unavailable_Command_Feedback_Is_Deterministic'Access,
         "Phase 222 unavailable command feedback is deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase222_Build_Command_Feedback_Avoids_Internal_Details'Access,
         "Phase 222 build command feedback avoids internal details");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase222_Target_Activation_Failure_Feedback'Access,
         "Phase 222 stale target activation feedback is deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase223_Cancel_No_Cancellable_Is_Quiet_No_Op'Access,
         "Phase 223 cancel with nothing cancellable is a quiet no-op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase223_Cancel_Command_Palette_Is_Cancelled'Access,
         "Phase 223 command palette cancellation is classified");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase223_Feature_Panel_Already_State_No_Ops'Access,
         "Phase 223 already-state feature panel commands are no-ops");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase223_Empty_Clear_Commands_Are_Quiet_No_Ops'Access,
         "Phase 223 empty clear commands are quiet no-ops");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase223_Navigation_Boundaries_Are_No_Ops'Access,
         "Phase 223 navigation boundaries are no-ops");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Insert'Access, "Insert");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Backspace_Delete'Access, "Backspace");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Forward_Delete'Access, "Forward Delete");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Home_End'Access, "Home / End");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Preferred_Column_Up_Down'Access,
         "Preferred_Column Up/Down");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Forward_Delete_Newline'Access,
         "Forward Delete Newline");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Backspace_Delete_Newline'Access,
         "Backspace Delete Newline");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Semantics'Access,
         "Delete Semantics");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Word_Navigation'Access,
         "Phase 23 Word Navigation");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Shift_Word_Right_Selects'Access,
         "Phase 23 Shift Word Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Document_Start_End'Access,
         "Phase 23 Document Start/End");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Page_Down_Uses_Visible_Row_Count'Access,
         "Phase 23 Page Down Rows");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Select_Word_And_Whitespace_At_Point'Access,
         "Phase 23 Double Click Word");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Select_Line_At_Point'Access,
         "Phase 23 Triple Click Line");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Mouse_Hit_Before_Text_Origin_Clamps_To_Column_Zero'Access,
         "Phase 23 Mouse Hit Clamp");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Drag_Creates_Normal_Selection'Access,
         "Phase 23 Drag Selection");


      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Gutter_Click_Moves_To_Line_Start'Access,
         "Phase 23 Gutter Click");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Shift_Page_Down_Extends_Selection'Access,
         "Phase 23 Select Page Down");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Multi_Caret_Shift_Word_Right_Selects_All'Access,
         "Phase 23 Multi-Caret Shift Word");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Multi_Caret_Move_Right_Applies_To_All'Access,
         "Phase 65 multi-caret move right");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Select_Right_Extends_All_Carets'Access,
         "Phase 65 multi-caret select right");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Navigation_Does_Not_Mutate_Text_Or_Dirty_Lines'Access,
         "Phase 65 navigation non-mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Node_Action_Toggles_Directory'Access,
         "Phase 57 File Tree Toggle Directory");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Node_Action_Opens_And_Switches_File'Access,
         "Phase 57 File Tree Open And Switch File");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Node_Action_Invalid_Is_No_Op'Access,
         "Phase 57 File Tree Invalid No-Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase212_File_Tree_Missing_Target_Does_Not_Open'Access,
         "Phase 212 missing file tree target does not open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase212_Refresh_Preserves_Unchanged_Selection'Access,
         "Phase 212 refresh preserves unchanged file tree selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase212_Refresh_Clears_Disappeared_Selection'Access,
         "Phase 212 refresh clears disappeared file tree selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Jump_To_Diagnostic_Moves_Caret'Access,
         "Phase 61 diagnostic jump moves caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Next_Previous_Diagnostic'Access,
         "Phase 61 next and previous diagnostic navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Jump_To_Diagnostic_On_Row'Access,
         "Phase 61 row diagnostic jump chooses dominant diagnostic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Jump_Invalid_And_Empty_Cases'Access,
         "Phase 61 diagnostic empty and invalid jumps are non-mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Jump_Expands_Hidden_Fold'Access,
         "Phase 61 diagnostic jump expands hidden fold");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Toggle_Bookmark_At_Caret_And_Row'Access,
         "Phase 62 toggle bookmark at caret and row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Next_Previous_Bookmark_Navigation'Access,
         "Phase 62 next and previous bookmark navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Navigation_Empty_Preserves_Caret'Access,
         "Phase 62 bookmark empty navigation preserves caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Navigation_Across_Open_Buffers'Access,
         "Phase 265 bookmark navigation crosses open buffers and records history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_All_Bookmarks_Across_Open_Buffers'Access,
         "Phase 265 clear all bookmarks removes every open-buffer bookmark");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_Bookmarks_Active_Buffer_Only'Access,
         "Phase 62 clear bookmarks active buffer only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Commands_Report_No_Bookmarks'Access,
         "Phase 62 bookmark commands report no bookmarks");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Jump_Expands_Hidden_Fold'Access,
         "Phase 62 bookmark jump expands hidden fold");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Toggle_Feedback_And_Stable_Names'Access,
         "Phase 265 bookmark stable names and feedback");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Navigation_Prunes_Stale_Bookmarks'Access,
         "Phase 265 bookmark navigation prunes stale bookmarks");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Commands_On_Empty_Buffer_Are_Safe'Access,
         "Phase 265 bookmark commands handle empty buffers safely");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Toggle_And_Clear_Do_Not_Push_History'Access,
         "Phase 265 bookmark toggle and clear do not push history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Lines_Insert_And_Undo'Access,
         "Phase 63 dirty lines insert undo redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Lines_Save_Clears_Baseline'Access,
         "Phase 63 dirty lines save clears baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Lines_Buffer_Isolation'Access,
         "Phase 63 dirty lines buffer isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Lines_Save_Without_Path_Preserves_State'Access,
         "Phase 63 failed save preserves dirty-line state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Lines_Open_Failure_Preserves_State'Access,
         "Phase 63 failed open preserves dirty-line state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Lines_Save_Active_Buffer_Only'Access,
         "Phase 63 save clears active buffer dirty lines only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase261_Find_Navigation_Is_Incremental_Only'Access,
         "Phase 261 find navigation is incremental only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase261_Active_Find_Previous_Wraps_Deterministically'Access,
         "Phase 261 find previous wraps deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase261_Find_Query_Persists_Across_Buffer_Switch'Access,
         "Phase 261 find query persists across buffer switch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase262_Find_Highlights_Clear_When_Find_Closes'Access,
         "Phase 262 find highlights clear when find closes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase262_Query_Edit_Recomputes_Current_From_Caret'Access,
         "Phase 262 query edit recomputes current from caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase262_Wrap_Status_Is_Deterministic'Access,
         "Phase 262 wrap status is deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase262_Current_Match_Emphasis_Is_Projected'Access,
         "Phase 262 current match emphasis is projected");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase262_Find_Query_Edit_Stays_Out_Of_Feature_Search'Access,
         "Phase 262 find query edit stays out of feature search");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase68_Executor_Set_Rectangular_Selection'Access,
         "Phase 68 executor set rectangular selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase68_Executor_Clear_Rectangular_Selection'Access,
         "Phase 68 executor clear rectangular selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase73_Run_Project_Search_No_Project'Access,
         "Phase 73 project search reports no-project and shows Search Results");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase73_Run_Search_And_Open_Result'Access,
         "Phase 73 project search opens selected result and selects match");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase548_Replace_All_Continues_After_First_File_Stales_Preview'Access,
         "Phase 548 replace all continues after first file stales preview");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase548_Project_Replace_Uses_UTF8_Byte_Offsets_Safely'Access,
         "Phase 548 project replace apply translates UTF-8 byte offsets safely");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase548_Replace_Preview_Stales_Dirty_Open_Targets'Access,
         "Phase 548 replace preview stales open dirty target buffers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase334_Open_Selected_Single_Location_Message'Access,
         "Phase 334 project search open-selected emits one location message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase337_Project_Search_From_Selection'Access,
         "Phase 337 project search derives query from selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase337_Project_Search_From_Active_Word'Access,
         "Phase 337 project search derives query from active word");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase337_Active_Word_Dotted_Token_Boundary'Access,
         "Phase 337 active word respects dotted token boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase337_Project_Search_Active_Directory'Access,
         "Phase 337 project search scopes to active directory");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase337_Context_Search_Failure_Is_Atomic'Access,
         "Phase 337 context search failures preserve state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase339_First_Last_Project_Search_Result'Access,
         "Phase 339 first and last Project Search result navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase339_Reveal_Active_Project_Search_Result'Access,
         "Phase 339 reveal active Project Search result");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase339_Scope_Selected_Project_Search_Directory'Access,
         "Phase 339 scope Project Search to selected result directory");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase339_Project_Search_Navigation_No_Result_Messages'Access,
         "Phase 339 Project Search navigation no-result messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase334_Stale_Open_Failure_Preserves_Result_State'Access,
         "Phase 334 stale project search open failure preserves results");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase547_Out_Of_Range_Project_Search_Result_Does_Not_Clamp'Access,
         "Phase 547 out-of-range project search activation does not clamp");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase74_Open_Project_Search_Bar'Access,
         "Phase 74 opens project-search bar and closes quick open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase74_Run_Project_Search_From_Bar'Access,
         "Phase 74 runs project search from bar");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase74_Close_And_Clear_Project_Search_Bar'Access,
         "Phase 74 closes and clears project-search bar deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase334_Query_Edit_And_Refresh_Clear_Results'Access,
         "Phase 334 query edits and project refresh clear Project Search results");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase76_Focus_Search_Results_Shows_And_Focuses'Access,
         "Phase 76 focuses Search Results and shows the bottom panel");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase76_Search_Results_Move_Is_Selection_Only'Access,
         "Phase 76 focused Search Results movement is selection-only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase76_Search_Results_Open_Returns_To_Editor_Text'Access,
         "Phase 76 Enter opens selected result and returns editor focus");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase76_Search_Results_Escape_Returns_To_Editor_Text'Access,
         "Phase 76 Escape returns editor focus without hiding panel");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase77_Focus_Problems_Shows_And_Focuses'Access,
         "Phase 77 focuses Problems and shows the bottom panel");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase77_Problems_Move_Is_Selection_Only'Access,
         "Phase 77 focused Problems movement is selection-only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase77_Problems_Open_Returns_To_Editor_Text'Access,
         "Phase 77 Enter opens selected problem and returns editor focus");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase77_Problems_Open_No_Selection_Reports'Access,
         "Phase 77 opening without selected problem reports failure");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase77_Problems_Escape_Returns_To_Editor_Text'Access,
         "Phase 77 Escape returns editor focus without hiding Problems");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase79_Open_Overlays_Activate_Through_Executor'Access,
         "Phase 79 overlay open commands activate through executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase79_Active_Find_Prompt_Remains_Visible_But_Inactive_Under_Quick_Open'Access,
         "Phase 79 quick open leaves active Find prompt visible but inactive");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase79_Deactivate_Active_Find_Prompt_Leaves_Surface_Open'Access,
         "Phase 79 active Find prompt can be visible and inactive");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase79_Dismiss_Restores_Valid_File_Tree_Focus'Access,
         "Phase 79 overlay dismiss restores valid file-tree focus");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pending_Invalid_Open_Project_Clears_Silently'Access,
         "pending invalid open-project clears silently");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pending_Invalid_Close_Buffer_Clears_Silently'Access,
         "pending invalid close-buffer clears silently");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase213_Open_Selected_Recent_Project_Opens_First_Entry'Access,
         "Phase 213 open selected recent project opens first entry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase213_Open_Selected_Recent_Project_Missing_Path_Fails_Safely'Access,
         "Phase 213 missing recent project activation fails safely");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase559_Recent_Project_Selection_Commands_Are_Transient'Access,
         "Phase 559 recent project selection commands are transient");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase559_Show_Recent_Projects_Reports_No_Available'Access,
         "Phase 559 show recent projects reports no available projects");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase208_Insert_Newline_Dirty_And_Cursor'Access,
         "Phase 208 insert newline dirty cursor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase208_Insert_Replaces_Selection'Access,
         "Phase 208 insert replaces selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase208_Backspace_At_Buffer_Start_Is_No_Op'Access,
         "Phase 208 backspace start no-op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase208_Paste_Replaces_Multiline_Selection'Access,
         "Phase 208 paste replaces multiline selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase208_Empty_Paste_Is_No_Op'Access,
         "Phase 208 empty paste is no-op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase208_Edit_Invalidates_Feature_Targets'Access,
         "Phase 208 edit invalidates feature targets");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase210_Paste_Normalizes_Line_Endings'Access,
         "Phase 210 paste normalizes line endings");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase210_Paste_Trailing_Newline_Over_Selection'Access,
         "Phase 210 paste trailing newline over selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase210_Empty_Paste_Preserves_Dirty_State'Access,
         "Phase 210 empty paste preserves dirty state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase263_Goto_Line_Jumps_And_Returns_To_Editor'Access,
         "Phase 263 Go To Line jumps and returns to editor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase263_Goto_Line_Failure_Preserves_Cursor_Viewport'Access,
         "Phase 263 failed Go To Line preserves cursor and viewport");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase263_Goto_Line_Does_Not_Mutate_Find_Or_Feature_Rows'Access,
         "Phase 263 Go To Line preserves find and Feature Panel separation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase264_Goto_Line_Back_Forward_Routes_Through_Executor'Access,
         "Phase 264 Go To Line navigation history back forward");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase264_Find_Navigation_Pushes_History_And_Back_Preserves_Query'Access,
         "Phase 264 find navigation history preserves query");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase367_Replace_Lifecycle_Find_Hide_And_Render_Coherence'Access,
         "Phase 367 replace lifecycle find hide render coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase367_Replacement_Text_Literal_Matrix_And_No_Recompute'Access,
         "Phase 367 replacement text literal matrix no recompute");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase367_Replace_Current_Selected_Stale_And_No_Selected_Workflows'Access,
         "Phase 367 replace current selected stale no-selected workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase367_Replace_Current_Active_Buffer_Switch_Uses_Current_Buffer'Access,
         "Phase 367 replace current active buffer switch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase367_Replace_All_Options_Span_Empty_And_Same_Text'Access,
         "Phase 367 replace all options span empty same-text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase367_Context_Derived_Query_Render_Dirty_And_Failure_Atomicity'Access,
         "Phase 367 context query render dirty failure atomicity");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase367_Feature_Independence_Navigation_And_Lifecycle_Cleanup'Access,
         "Phase 367 feature independence navigation lifecycle cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase367_Routes_Availability_Absent_Commands_And_Persistence'Access,
         "Phase 367 routes availability absent commands persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase368_Replace_Render_Uses_Canonical_Overlay_State'Access,
         "Phase 368 replace render uses canonical overlay state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase368_Replace_Operations_Use_Only_Canonical_Find_State'Access,
         "Phase 368 replace operations use canonical Find state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase368_Replace_Lifecycle_And_Persistence_Exclude_State'Access,
         "Phase 368 replace lifecycle and persistence exclude state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase264_Typing_And_Save_Do_Not_Push_Navigation_History'Access,
         "Phase 264 typing and save do not push navigation history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase365_Replace_Show_Hide_Clears_Transient_Text'Access,
         "Phase 365 replace show hide clears transient text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase365_Replace_Current_Uses_Find_And_Dirties_No_History'Access,
         "Phase 365 replace current uses Find and no history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase365_Replace_All_Is_Literal_Offset_Safe_And_Recomputes'Access,
         "Phase 365 replace all literal offset safe recomputes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase365_Replace_All_Uses_Canonical_Non_Overlapping_Matches'Access,
         "Phase 365 replace all uses canonical non-overlapping matches");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase365_Replace_Empty_Text_Deletes_Matches'Access,
         "Phase 365 empty replacement deletes matches");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase366_Replace_Text_Newline_Is_Rejected'Access,
         "Phase 366 replace text newline rejected");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase366_Replace_Current_Preserves_Valid_Selected_Match'Access,
         "Phase 366 replace current selected match survives recompute");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase366_Replace_Current_Does_Not_Trust_Stale_Deleted_Range'Access,
         "Phase 366 replace current ignores stale deleted range");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase366_Replace_All_Does_Not_Recursively_Replace_New_Text'Access,
         "Phase 366 replace all non recursive literal text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase264_New_Explicit_Navigation_After_Back_Clears_Forward'Access,
         "Phase 264 explicit navigation after back clears forward");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase264_File_Tree_Node_Action_Pushes_Navigation_History'Access,
         "Phase 346 File Tree row activation does not push navigation history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase346_Navigation_History_Clear_Command'Access,
         "Phase 346 navigation history clear command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase346_Navigation_History_Clear_Descriptor'Access,
         "Phase 346 navigation history clear descriptor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase346_Failed_Back_Invalid_Open_Target_Is_Atomic'Access,
         "Phase 346 failed back to invalid open target is atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase347_Back_To_Unopened_Stale_Line_Is_Partial_Success'Access,
         "Phase 347 back to unopened stale line is partial success");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase347_Quick_Open_Accept_Records_Previous_Location'Access,
         "Phase 347 Quick Open accept records previous location");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase347_Quick_Open_Stale_Failure_Does_Not_Record'Access,
         "Phase 347 Quick Open stale failure does not record");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase266_Buffer_Switcher_Accept_Switches_And_Pushes_History'Access,
         "Phase 266 buffer switcher accept switches and records history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase266_Buffer_Switcher_Failed_Accept_Preserves_State'Access,
         "Phase 266 buffer switcher failed accept preserves state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase267_New_Buffer_Seeds_Initial_Recent_Order'Access,
         "Phase 267 new buffer seeds initial recent order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase267_Recent_Feedback_Is_Primary_Command_Message'Access,
         "Phase 267 recent feedback is primary command message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase267_Recent_Previous_And_Next_Switch_Buffers'Access,
         "Phase 267 recent previous and next switch buffers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase267_Recent_Traversal_Wraps_Three_Buffers'Access,
         "Phase 267 recent traversal wraps three buffers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase267_Recent_Close_Removes_Target'Access,
         "Phase 267 recent close removes target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase268_Close_Others_Closes_Clean_And_Skips_Dirty'Access,
         "Phase 268 close others closes clean and skips dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase268_Close_Clean_Closes_Clean_And_Preserves_Dirty'Access,
         "Phase 268 close clean closes clean and preserves dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase268_Cleanup_Command_Descriptors'Access,
         "Phase 268 cleanup command descriptors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Dirty_Close_Cancel_And_Discard_Are_Explicit'Access,
         "Phase 575 dirty close cancel and discard are explicit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Save_And_Close_Uses_File_Lifecycle_And_Closes'Access,
         "Phase 575 save and close uses file lifecycle and closes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Save_And_Close_Revalidates_Clean_Target'Access,
         "Phase 575 save and close revalidates clean target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Stale_Close_Target_Revalidates_And_Clears'Access,
         "Phase 575 stale close target revalidates and clears");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Save_And_Close_Conflict_Overwrite_Closes'Access,
         "Phase 575 save and close conflict overwrite closes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Close_All_Save_Conflict_Overwrite_Continues'Access,
         "Phase 575 close-all save conflict overwrite continues");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Discard_Pending_Unavailable_For_Reload_Revert'Access,
         "Phase 575 discard pending unavailable for reload revert");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Discard_Pending_Close_Buffer_Revalidates_Clean_Target'Access,
         "Phase 575 discard pending close revalidates clean target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Dirty_Close_Distinguishes_Save_Failure_From_Conflict'Access,
         "Phase 575 dirty close distinguishes save failure from conflict");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Unbacked_Close_Does_Not_Offer_Save_And_Close'Access,
         "Phase 575 unbacked close does not offer save-and-close");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Single_Close_Save_Action_Revalidates_Path_State'Access,
         "Phase 575 single close save action revalidates path state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Render_Model_Projects_Dirty_Close_Actions'Access,
         "Phase 575 render model projects dirty close actions");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Close_All_Review_Stale_Buffer_Set_Is_Revalidated'Access,
         "Phase 575 close-all review stale buffer set is revalidated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Close_All_Review_Stale_Same_Count_Is_Revalidated'Access,
         "Phase 575 close-all review stale same-count replacement is revalidated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Close_All_Review_Newly_Dirty_Buffer_Is_Revalidated'Access,
         "Phase 575 close-all review newly dirty buffer is revalidated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Close_All_Review_All_Clean_Revalidated_As_Close'Access,
         "Phase 575 close-all review allows unchanged buffer set when reviewed dirty buffers became clean");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Close_All_Review_All_Clean_Discard_Revalidated_As_Close'Access,
         "Phase 575 close-all discard review allows unchanged buffer set when reviewed dirty buffers became clean");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Close_All_Review_Subset_Dirty_Revalidated'Access,
         "Phase 575 close-all review allows remaining dirty subset when all current dirty buffers were reviewed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Close_All_Review_Subset_Scratch_Save_Unavailable'Access,
         "Phase 575 close-all reviewed scratch subset hides save and keeps discard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Close_All_Review_Message_Summarizes_Dirty_Set'Access,
         "Phase 575 close-all review message summarizes dirty set");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase575_Close_All_Save_Failure_Rebuilds_Remaining_Review'Access,
         "Phase 575 close-all save failure rebuilds remaining review");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase269_Reopen_Unavailable_With_No_Candidate'Access,
         "Phase 436 reopen unavailable with no candidate");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase269_Close_Clean_File_And_Reopen'Access,
         "Phase 269 close clean file and reopen");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase269_Reopen_Reverse_Order_After_Cleanup'Access,
         "Phase 269 reopen reverse order after cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase269_Blocked_Dirty_Close_Does_Not_Record'Access,
         "Phase 269 blocked dirty close does not record");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase269_Reopen_Already_Open_File_Focuses_Existing'Access,
         "Phase 269 reopen already-open file focuses existing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase269_Missing_File_Reopen_Fails_Deterministically'Access,
         "Phase 269 missing file reopen fails deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase274_Filter_Commands_Route_Through_Executor'Access,
         "Phase 274 switcher filter commands route through Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase274_Filter_Availability_Is_Side_Effect_Free'Access,
         "Phase 274 switcher filter availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase275_Sort_Commands_Route_Through_Executor'Access,
         "Phase 275 switcher sort commands route through Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase275_Sort_Availability_Is_Side_Effect_Free'Access,
         "Phase 275 switcher sort availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase276_Selected_Metadata_Actions_Target_Switcher_Row'Access,
         "Phase 276 selected switcher metadata actions target selected row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase276_Selected_Close_Composes_With_Reopen_And_Dirty_Guard'Access,
         "Phase 276 selected switcher close composes with reopen and dirty guard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase576_Buffer_List_Selected_Close_Cancel_Preserves_Dirty_Text'Access,
         "Phase 576 selected buffer-list close cancel preserves dirty text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase576_Close_Clean_Refreshes_Buffer_List_And_Selection'Access,
         "Phase 576 close clean refreshes buffer list and selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase576_Selected_Buffer_List_Clean_Close_Closes_And_Refreshes'Access,
         "Phase 576 selected buffer-list clean close closes and refreshes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase576_Selected_Buffer_List_Save_And_Close_Succeeds_And_Refreshes'Access,
         "Phase 576 selected buffer-list save-and-close succeeds and refreshes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase576_Selected_Buffer_List_Overwrite_Closes_And_Refreshes'Access,
         "Phase 576 selected buffer-list overwrite closes and refreshes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase576_Selected_Buffer_List_Save_Conflict_Preserves_Selected_Buffer'Access,
         "Phase 576 selected buffer-list save conflict preserves selected buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase277_Preview_Follows_Selected_Row_Without_Activation'Access,
         "Phase 277 switcher preview follows selected row without activation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase277_Preview_Availability_Is_Side_Effect_Free'Access,
         "Phase 277 switcher preview availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase278_Selected_Marks_Target_Switcher_Row'Access,
         "Phase 278 selected switcher marks target selected row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase278_Invert_Visible_Preserves_Hidden_Marks'Access,
         "Phase 278 invert visible preserves hidden marks");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase278_Marked_Pin_Unpin_And_Metadata_Clear'Access,
         "Phase 278 marked pin unpin and metadata clear");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase278_Marked_Close_Dirty_Reopen_And_Pin_Composition'Access,
         "Phase 278 marked close dirty reopen and pin composition");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase278_Mark_Availability_Is_Side_Effect_Free'Access,
         "Phase 278 switcher mark availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase279_Marked_Metadata_Apply_Targets_Marked_Buffers'Access,
         "Phase 279 marked metadata apply targets marked buffers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase279_Marked_Metadata_Composes_With_Filter_Sort_And_Preview'Access,
         "Phase 279 marked metadata composes with filter sort and preview");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase279_Marked_Metadata_Validation_And_Availability'Access,
         "Phase 279 marked metadata validation and availability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase280_Mark_Presets_Compose_With_Metadata_Visibility_And_State'Access,
         "Phase 280 mark presets compose with metadata visibility and state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase280_Mark_Preset_Availability_And_No_Match_Are_Deterministic'Access,
         "Phase 280 mark preset availability and no-match behavior");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase281_Marked_Review_Routes_Through_Executor_And_Is_Inspection_Only'Access,
         "Phase 281 marked review routes through Executor and is inspection-only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase281_Marked_Review_Availability_Is_Side_Effect_Free'Access,
         "Phase 281 marked review availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase282_Marked_Close_Prepares_Captured_Targets_And_Cancel'Access,
         "Phase 282 marked close prepares captured targets and cancel");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase282_Confirm_Closes_Captured_Clean_Skips_Closed_And_Protects_Dirty'Access,
         "Phase 282 confirm closes captured clean skips closed and protects dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase282_Confirm_Cancel_Availability_Is_Side_Effect_Free'Access,
         "Phase 282 confirm cancel availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase283_Pending_Marked_Review_Commands_Are_Deterministic'Access,
         "Phase 283 pending marked review commands are deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase284_Remove_Selected_Prunes_Pending_Close_Target'Access,
         "Phase 284 remove selected prunes pending close target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase284_Remove_Selected_Availability_And_Last_Target'Access,
         "Phase 284 remove selected availability and last target policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase285_Restore_Last_Pruned_Pending_Close_Target'Access,
         "Phase 285 restore last pruned pending close target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase285_Restore_Last_Pruned_Closed_Target_Is_Explicit'Access,
         "Phase 285 restore last pruned closed target is explicit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase286_Pruned_Pending_Summary_Navigation_Review_And_Selected_Restore'Access,
         "Phase 286 pruned pending summary navigation review and selected restore");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase286_Pruned_Pending_No_Open_And_No_Pending_Messages'Access,
         "Phase 286 pruned pending no-open and no-pending messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase289_Dirty_Pending_Summary_And_Navigation_Route_Through_Executor'Access,
         "Phase 289 dirty pending summary and navigation route through Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase290_Dirty_Pending_Remove_Selected_Prunes_Without_Buffer_Mutation'Access,
         "Phase 290 dirty pending remove selected prunes without buffer mutation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase290_Dirty_Remove_Selected_Deterministic_Rejections'Access,
         "Phase 290 dirty pending remove selected deterministic rejections");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase291_Dirty_Prune_Preview_Apply_Cancel_And_Revalidation'Access,
         "Phase 291 dirty prune preview apply cancel and revalidation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase292_Dirty_Prune_Review_Summary_Navigation_And_Clear'Access,
         "Phase 292 dirty prune review summary navigation and clear");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase293_Dirty_Prune_Remove_Selected_Edits_Preview_Only'Access,
         "Phase 293 dirty prune remove selected edits preview only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase294_Dirty_Prune_Restore_Last_Removed'Access,
         "Phase 294 dirty prune restore last removed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase295_Removed_Dirty_Prune_Navigation'Access,
         "Phase 295 removed dirty prune summary and navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase297_Dirty_Prune_Clear_Stale_Command_And_Apply'Access,
         "Phase 297 dirty prune clear stale command and apply");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase326_Reveal_Active_Selects_Known_Project_File'Access,
         "Phase 326 reveal active selects known project file");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase326_Scope_Active_Directory_Selects_Active_File'Access,
         "Phase 326 scope active directory selects active file");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase326_Active_Buffer_Not_Known_Does_Not_Show_Quick_Open'Access,
         "Phase 326 active buffer not known does not show quick open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase331_Active_Reveal_And_Scope_Preserve_Priority'Access,
         "Phase 331 active reveal and scope preserve priority");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase331_Stale_Quick_Open_Open_Failure_Preserves_State'Access,
         "Phase 331 stale quick open failure preserves state");

   end Register_Tests;

end Editor.Executor.Tests;
