with Editor.Test_Temp;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;

with Editor.Commands;
with Editor.Executor;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Pending_Transitions;
with Editor.Messages;
with Editor.Test_Helper;
with Text_Buffer;

package body Editor.Files.Test_Helpers is

   use type Ada.Directories.File_Kind;
   use type Ada.Streams.Stream_IO.Count;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path (Editor.Test_Temp.Base & "/editor-tests");
      return Ada.Directories.Compose (Editor.Test_Temp.Base & "/editor-tests", Name);
   end Temp_Path;

   procedure Write_Bytes (Path : String; Bytes : String) is
      F : Stream_IO.File_Type;
   begin
      Stream_IO.Create (F, Stream_IO.Out_File, Path);
      if Bytes'Length > 0 then
         declare
            Raw : Ada.Streams.Stream_Element_Array
              (1 .. Ada.Streams.Stream_Element_Offset (Bytes'Length));
         begin
            for I in Bytes'Range loop
               Raw (Ada.Streams.Stream_Element_Offset (I - Bytes'First + 1)) :=
                 Ada.Streams.Stream_Element (Character'Pos (Bytes (I)));
            end loop;
            Stream_IO.Write (F, Raw);
         end;
      end if;
      Stream_IO.Close (F);
   end Write_Bytes;

   function Read_Bytes (Path : String) return String is
      F : Stream_IO.File_Type;
   begin
      Stream_IO.Open (F, Stream_IO.In_File, Path);
      declare
         Size : constant Stream_IO.Count := Stream_IO.Size (F);
      begin
         if Size = 0 then
            Stream_IO.Close (F);
            return "";
         end if;

         declare
            Raw  : Ada.Streams.Stream_Element_Array
              (1 .. Ada.Streams.Stream_Element_Offset (Size));
            Last : Ada.Streams.Stream_Element_Offset;
            S    : String (1 .. Natural (Size));
         begin
            Stream_IO.Read (F, Raw, Last);
            for I in Raw'Range loop
               S (Natural (I)) := Character'Val (Integer (Raw (I)));
            end loop;
            Stream_IO.Close (F);
            return S;
         end;
      end;
   end Read_Bytes;

   function Buffer_Text (S : Editor.State.State_Type) return String is
   begin
      return Text_Buffer.UTF8_Text (S.Buffer);
   end Buffer_Text;

   procedure Insert_Text_At
     (S    : in out Editor.State.State_Type;
      Pos  : Natural;
      Text : String)
   is
      Offset : Natural := 0;
   begin
      for Ch of Text loop
         Editor.Executor.Execute_No_Log
           (S, Editor.Test_Helper.Insert (Pos + Offset, Ch));
         Offset := Offset + 1;
      end loop;
   end Insert_Text_At;

   procedure Execute_Revert_And_Confirm
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.File_Save_Basic_Commands.Execute_Revert_Active_Buffer (S);
      if Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         Editor.Messages.Clear (S.Messages);
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Retry_Pending_Transition);
      end if;
   end Execute_Revert_And_Confirm;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         if Ada.Directories.Kind (Path) = Ada.Directories.Directory then
            Ada.Directories.Delete_Directory (Path);
         else
            Ada.Directories.Delete_File (Path);
         end if;
      end if;
   end Remove_If_Exists;

end Editor.Files.Test_Helpers;
