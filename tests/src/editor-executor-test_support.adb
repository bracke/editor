with Ada.Directories;
with Ada.Containers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Editor.Buffers;
with Editor.Cursors;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Recent_Projects;
with Editor.View;
with Text_Buffer;

package body Editor.Executor.Test_Support is

   use type Ada.Directories.File_Kind;
   use type Ada.Containers.Count_Type;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return Ada.Directories.Compose
        ("/tmp/editor-tests", "exec_" & Name);
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

   procedure Write_Text_File (Path : String; Text : String) renames Write_Bytes;

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

   procedure Init_Executor_Test_State (S : out Editor.State.State_Type) is
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.View.Reset;
      Use_Executor_Recent_Config;
      Remove_File_If_Exists (Editor.Recent_Projects.Recent_Projects_File_Path);
      Editor.State.Init (S);
   end Init_Executor_Test_State;

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

   procedure Select_Diagnostic_By_Message
     (S       : in out Editor.State.State_Type;
      Message : String)
   is
   begin
      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) loop
         if Editor.Feature_Diagnostics.Item_Message (S.Feature_Diagnostics, I) =
           Message
         then
            Editor.Feature_Panel.Select_Row (S.Feature_Panel, I);
            return;
         end if;
      end loop;
   end Select_Diagnostic_By_Message;

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

   function Numbered_Lines
     (Count       : Positive;
      Needle_Line : Natural := 0) return String
   is
      Text : Unbounded_String := Null_Unbounded_String;
   begin
      for Line in 1 .. Count loop
         if Line = Needle_Line then
            Append
              (Text,
               "line " &
               Ada.Strings.Fixed.Trim (Natural'Image (Line), Ada.Strings.Both) &
               " needle");
         else
            Append
              (Text,
               "line " &
               Ada.Strings.Fixed.Trim (Natural'Image (Line), Ada.Strings.Both));
         end if;
         if Line < Count then
            Append (Text, ASCII.LF);
         end if;
      end loop;
      return To_String (Text);
   end Numbered_Lines;

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
      Write_Text_File
        (Ada.Directories.Compose (Editor_Dir, "executor.adb"),
         "procedure Execute_Command is" & ASCII.LF
         & "begin" & ASCII.LF
         & "   null;" & ASCII.LF
         & "end Execute_Command;" & ASCII.LF);
      Write_Text_File
        (Ada.Directories.Compose (Other_Dir, "other.adb"),
         "procedure Execute_Command is" & ASCII.LF
         & "begin null; end Execute_Command;" & ASCII.LF);
   end Build_Project_Search_Context_Fixture;

   procedure Cleanup_Project_Search_Context_Fixture (Root : String) is
   begin
      Remove_Tree_If_Exists (Root);
   end Cleanup_Project_Search_Context_Fixture;

end Editor.Executor.Test_Support;
