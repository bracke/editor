with Ada.Calendar;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.History;
with Editor.State;
with Editor.UTF8;
with Editor.View;
with GNAT.OS_Lib;

package body Editor.Files is

   package Stream_IO renames Ada.Streams.Stream_IO;
   use type Ada.Streams.Stream_Element_Offset;
   use type Ada.Calendar.Time;
   use type Ada.Directories.File_Kind;
   use type Stream_IO.Count;


   function Current_Token_Label
     (Path  : String;
      Found : out Boolean) return String
   is
      use type Ada.Directories.File_Kind;
      Size_Text : Unbounded_String;
      Time_Text : Unbounded_String;
   begin
      Found := False;
      if Path'Length = 0
        or else not Ada.Directories.Exists (Path)
        or else Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File
      then
         return "";
      end if;

      --  Metadata identity is only useful for lifecycle reads when the file
      --  is still readable.  A command-boundary check must surface a regular
      --  but unreadable backing file as unreadable, not as an unchanged token
      --  match derived from stat-only metadata.
      if not GNAT.OS_Lib.Is_Readable_File
        (Canonical_Path_For_Existing_File (Path))
      then
         return "";
      end if;

      Size_Text := To_Unbounded_String
        (Ada.Directories.File_Size'Image (Ada.Directories.Size (Path)));
      Time_Text := To_Unbounded_String
        (Duration'Image
           (Ada.Directories.Modification_Time (Path) -
            Ada.Calendar.Time_Of (Year => 1901, Month => 1, Day => 1)));
      Found := True;
      return To_String (Size_Text & To_Unbounded_String (":") & Time_Text);
   exception
      when others =>
         Found := False;
         return "";
   end Current_Token_Label;

   function External_Change_Status
     (Path        : String;
      Known       : Boolean;
      Known_Label : String) return File_External_Change_Status
   is
      Found : Boolean := False;
      Label : constant String := Current_Token_Label (Path, Found);
   begin
      if not Known then
         return File_External_Status_Unknown;
      elsif Path'Length = 0 or else not Ada.Directories.Exists (Path) then
         return File_External_Status_Missing;
      elsif Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File then
         return File_External_Status_Replaced;
      elsif not Found then
         return File_External_Status_Unreadable;
      elsif Label = Known_Label then
         return File_External_Status_Unchanged;
      else
         return File_External_Status_Modified;
      end if;
   exception
      when others =>
         return File_External_Status_Unreadable;
   end External_Change_Status;

   function Is_Invalid_Path (Path : String) return Boolean is
   begin
      return Path'Length = 0;
   end Is_Invalid_Path;

   function Canonical_Path_For_Existing_File
     (Path : String) return String
   is
   begin
      if Path'Length = 0 then
         return Path;
      elsif Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File
      then
         return Ada.Directories.Full_Name (Path);
      else
         return Path;
      end if;
   exception
      when others =>
         return Path;
   end Canonical_Path_For_Existing_File;

   function Existing_File_Is_Writable
     (Path : String) return Boolean
   is
      Canonical : constant String := Canonical_Path_For_Existing_File (Path);
   begin
      return Path'Length > 0
        and then Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File
        and then GNAT.OS_Lib.Is_Writable_File (Canonical);
   exception
      when others =>
         return False;
   end Existing_File_Is_Writable;

   function Display_Name_For_Path (Path : String) return String is
   begin
      if Path'Length = 0 then
         return "Untitled";
      end if;

      declare
         Name : constant String := Ada.Directories.Simple_Name (Path);
      begin
         if Name'Length = 0 then
            return Path;
         else
            return Name;
         end if;
      end;
   exception
      when others =>
         return Path;
   end Display_Name_For_Path;

   function Status_To_File_Status
     (Status : File_Open_Status) return File_Status
   is
   begin
      case Status is
         when File_Open_Ok =>
            return Ok;
         when File_Open_Not_Found =>
            return Not_Found;
         when File_Open_Is_Directory =>
            return Is_Directory;
         when File_Open_Permission_Denied =>
            return Permission_Denied;
         when File_Open_Invalid_Path =>
            return Invalid_Path;
         when File_Open_Decode_Error =>
            return Decode_Error;
         when File_Open_Read_Error =>
            return Io_Error;
      end case;
   end Status_To_File_Status;


   function Status_To_File_Status
     (Status : File_Save_Status) return File_Status
   is
   begin
      case Status is
         when File_Save_Ok =>
            return Ok;
         when File_Save_Invalid_Path | File_Save_No_Current_Path
            | File_Save_Parent_Unavailable =>
            return Invalid_Path;
         when File_Save_Is_Directory =>
            return Is_Directory;
         when File_Save_Permission_Denied =>
            return Permission_Denied;
         when File_Save_Write_Error =>
            return Io_Error;
      end case;
   end Status_To_File_Status;

   function Normalize_Text (Bytes : String; Text : out Unbounded_String)
      return File_Open_Status
   is
      Start : Integer := Bytes'First;
      I     : Integer := Bytes'First;
   begin
      Text := Null_Unbounded_String;

      if Bytes'Length >= 3
        and then Character'Pos (Bytes (Bytes'First)) = 16#EF#
        and then Character'Pos (Bytes (Bytes'First + 1)) = 16#BB#
        and then Character'Pos (Bytes (Bytes'First + 2)) = 16#BF#
      then
         Start := Bytes'First + 3;
      end if;

      I := Start;
      while I <= Bytes'Last loop
         if Bytes (I) = ASCII.NUL then
            return File_Open_Decode_Error;
         elsif Bytes (I) = ASCII.CR then
            Append (Text, ASCII.LF);
            if I < Bytes'Last and then Bytes (I + 1) = ASCII.LF then
               I := I + 1;
            end if;
         else
            Append (Text, Bytes (I));
         end if;

         I := I + 1;
      end loop;

      declare
         Count : Natural;
         pragma Unreferenced (Count);
      begin
         Count := Editor.UTF8.Code_Point_Count
           (To_String (Text), Editor.UTF8.Reject);
      exception
         when Editor.UTF8.Invalid_UTF8 =>
            return File_Open_Decode_Error;
      end;

      return File_Open_Ok;
   end Normalize_Text;

   function Open_File
     (Path : String) return File_Open_Result
   is
      F      : Stream_IO.File_Type;
      Result : File_Open_Result;
   begin
      Result.Path := To_Unbounded_String (Path);
      Result.Display_Name := To_Unbounded_String (Display_Name_For_Path (Path));

      if Is_Invalid_Path (Path) then
         Result.Status := File_Open_Invalid_Path;
         Result.Error_Text := To_Unbounded_String ("invalid path");
         return Result;
      end if;

      if not Ada.Directories.Exists (Path) then
         Result.Status := File_Open_Not_Found;
         Result.Error_Text := To_Unbounded_String ("not found");
         return Result;
      end if;

      if Ada.Directories.Kind (Path) = Ada.Directories.Directory then
         Result.Status := File_Open_Is_Directory;
         Result.Error_Text := To_Unbounded_String ("is a directory");
         return Result;
      elsif Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File then
         Result.Status := File_Open_Invalid_Path;
         Result.Error_Text := To_Unbounded_String ("not a regular file");
         return Result;
      end if;

      Result.Path := To_Unbounded_String (Canonical_Path_For_Existing_File (Path));
      Result.Display_Name := To_Unbounded_String
        (Display_Name_For_Path (To_String (Result.Path)));

      Stream_IO.Open (F, Stream_IO.In_File, To_String (Result.Path));

      declare
         Size : constant Stream_IO.Count := Stream_IO.Size (F);
      begin
         if Size > 0 then
            declare
               Raw  : Ada.Streams.Stream_Element_Array
                 (1 .. Ada.Streams.Stream_Element_Offset (Size));
               Last : Ada.Streams.Stream_Element_Offset;
               Bytes : String (1 .. Natural (Size));
               Text  : Unbounded_String;
               Status : File_Open_Status;
            begin
               Stream_IO.Read (F, Raw, Last);
               Stream_IO.Close (F);

               if Last /= Raw'Last then
                  Result.Status := File_Open_Read_Error;
                  Result.Error_Text := To_Unbounded_String ("read error");
                  return Result;
               end if;

               for J in Raw'Range loop
                  Bytes (Natural (J)) := Character'Val (Integer (Raw (J)));
               end loop;

               Status := Normalize_Text (Bytes, Text);
               if Status /= File_Open_Ok then
                  Result.Status := Status;
                  Result.Error_Text := To_Unbounded_String (Status_Message (Result));
                  return Result;
               end if;

               Result.Contents := Text;
            end;
         else
            Stream_IO.Close (F);
            Result.Contents := Null_Unbounded_String;
         end if;
      end;

      Result.Status := File_Open_Ok;
      Result.Error_Text := Null_Unbounded_String;
      return Result;

   exception
      when Ada.Directories.Name_Error | Stream_IO.Name_Error =>
         if Stream_IO.Is_Open (F) then
            Stream_IO.Close (F);
         end if;
         Result.Status := File_Open_Invalid_Path;
         Result.Error_Text := To_Unbounded_String ("invalid path");
         return Result;

      when Ada.Directories.Use_Error | Stream_IO.Use_Error =>
         if Stream_IO.Is_Open (F) then
            Stream_IO.Close (F);
         end if;
         Result.Status := File_Open_Permission_Denied;
         Result.Error_Text := To_Unbounded_String ("permission denied");
         return Result;

      when others =>
         if Stream_IO.Is_Open (F) then
            Stream_IO.Close (F);
         end if;
         Result.Status := File_Open_Read_Error;
         Result.Error_Text := To_Unbounded_String ("read error");
         return Result;
   end Open_File;

   function Is_Success
     (Result : File_Open_Result) return Boolean
   is
   begin
      return Result.Status = File_Open_Ok;
   end Is_Success;

   function Status_Message
     (Result : File_Open_Result) return String
   is
   begin
      if Length (Result.Error_Text) > 0 then
         return To_String (Result.Error_Text);
      end if;

      case Result.Status is
         when File_Open_Ok =>
            return "ok";
         when File_Open_Not_Found =>
            return "not found";
         when File_Open_Is_Directory =>
            return "is a directory";
         when File_Open_Permission_Denied =>
            return "permission denied";
         when File_Open_Read_Error =>
            return "read error";
         when File_Open_Invalid_Path =>
            return "invalid path";
         when File_Open_Decode_Error =>
            return "decode error";
      end case;
   end Status_Message;

   function Is_Success
     (Result : File_Save_Result) return Boolean
   is
   begin
      return Result.Status = File_Save_Ok;
   end Is_Success;

   function Is_Success
     (Result : File_Rename_Result) return Boolean
   is
   begin
      return Result.Status = File_Rename_Ok;
   end Is_Success;

   function Is_Success
     (Result : File_Delete_Result) return Boolean
   is
   begin
      return Result.Status = File_Delete_Ok;
   end Is_Success;

   function Is_Success
     (Result : File_Copy_Result) return Boolean
   is
   begin
      return Result.Status = File_Copy_Ok;
   end Is_Success;

   function Is_Success
     (Result : File_Move_Result) return Boolean
   is
   begin
      return Result.Status = File_Move_Ok;
   end Is_Success;

   function Status_Message
     (Result : File_Save_Result) return String
   is
   begin
      if Length (Result.Error_Text) > 0 then
         return To_String (Result.Error_Text);
      end if;

      case Result.Status is
         when File_Save_Ok =>
            return "ok";
         when File_Save_Invalid_Path =>
            return "invalid path";
         when File_Save_Parent_Unavailable =>
            return "parent directory is unavailable";
         when File_Save_Is_Directory =>
            return "path is a directory";
         when File_Save_Permission_Denied =>
            return "permission denied";
         when File_Save_Write_Error =>
            return "write error";
         when File_Save_No_Current_Path =>
            return "no file path";
      end case;
   end Status_Message;

   function Status_Message
     (Result : File_Rename_Result) return String
   is
   begin
      if Length (Result.Error_Text) > 0 then
         return To_String (Result.Error_Text);
      end if;

      case Result.Status is
         when File_Rename_Ok =>
            return "ok";
         when File_Rename_Invalid_Source =>
            return "invalid source";
         when File_Rename_Invalid_Target =>
            return "invalid target";
         when File_Rename_Source_Not_Found =>
            return "source not found";
         when File_Rename_Source_Is_Directory =>
            return "source is a directory";
         when File_Rename_Target_Exists =>
            return "target exists";
         when File_Rename_Permission_Denied =>
            return "permission denied";
         when File_Rename_Error =>
            return "rename error";
      end case;
   end Status_Message;

   function Status_Message
     (Result : File_Delete_Result) return String
   is
   begin
      if Length (Result.Error_Text) > 0 then
         return To_String (Result.Error_Text);
      end if;

      case Result.Status is
         when File_Delete_Ok =>
            return "ok";
         when File_Delete_Invalid_Source =>
            return "invalid source";
         when File_Delete_Source_Not_Found =>
            return "source not found";
         when File_Delete_Source_Is_Directory =>
            return "source is a directory";
         when File_Delete_Permission_Denied =>
            return "permission denied";
         when File_Delete_Error =>
            return "delete error";
      end case;
   end Status_Message;
   function Status_Message
     (Result : File_Copy_Result) return String
   is
   begin
      if Length (Result.Error_Text) > 0 then
         return To_String (Result.Error_Text);
      end if;

      case Result.Status is
         when File_Copy_Ok =>
            return "ok";
         when File_Copy_Invalid_Source =>
            return "invalid source";
         when File_Copy_Invalid_Target =>
            return "invalid target";
         when File_Copy_Source_Not_Found =>
            return "source not found";
         when File_Copy_Source_Is_Directory =>
            return "source is a directory";
         when File_Copy_Target_Exists =>
            return "target exists";
         when File_Copy_Permission_Denied =>
            return "permission denied";
         when File_Copy_Error =>
            return "copy error";
      end case;
   end Status_Message;


   function Delete_File
     (Source : String) return File_Delete_Result
   is
      Result : File_Delete_Result;
   begin
      Result.Source_Path := To_Unbounded_String (Source);
      Result.Display_Name := To_Unbounded_String (Display_Name_For_Path (Source));

      if Is_Invalid_Path (Source) then
         Result.Status := File_Delete_Invalid_Source;
         Result.Error_Text := To_Unbounded_String ("invalid source");
         return Result;
      end if;

      if not Ada.Directories.Exists (Source) then
         Result.Status := File_Delete_Source_Not_Found;
         Result.Error_Text := To_Unbounded_String ("source not found");
         return Result;
      elsif Ada.Directories.Kind (Source) = Ada.Directories.Directory then
         Result.Status := File_Delete_Source_Is_Directory;
         Result.Error_Text := To_Unbounded_String ("source is a directory");
         return Result;
      elsif Ada.Directories.Kind (Source) /= Ada.Directories.Ordinary_File then
         Result.Status := File_Delete_Invalid_Source;
         Result.Error_Text := To_Unbounded_String ("invalid source");
         return Result;
      end if;

      Result.Source_Path := To_Unbounded_String
        (Canonical_Path_For_Existing_File (Source));
      Result.Display_Name := To_Unbounded_String
        (Display_Name_For_Path (To_String (Result.Source_Path)));
      Ada.Directories.Delete_File (To_String (Result.Source_Path));
      Result.Status := File_Delete_Ok;
      Result.Error_Text := Null_Unbounded_String;
      return Result;

   exception
      when Ada.Directories.Name_Error =>
         Result.Status := File_Delete_Invalid_Source;
         Result.Error_Text := To_Unbounded_String ("invalid source");
         return Result;
      when Ada.Directories.Use_Error =>
         Result.Status := File_Delete_Permission_Denied;
         Result.Error_Text := To_Unbounded_String ("permission denied");
         return Result;
      when others =>
         Result.Status := File_Delete_Error;
         Result.Error_Text := To_Unbounded_String ("delete error");
         return Result;
   end Delete_File;

   function Copy_File
     (Source : String;
      Target : String) return File_Copy_Result
   is
      Source_File : Stream_IO.File_Type;
      Target_File : Stream_IO.File_Type;
      Result      : File_Copy_Result;
   begin
      Result.Source_Path := To_Unbounded_String (Source);
      Result.Target_Path := To_Unbounded_String (Target);
      Result.Display_Name := To_Unbounded_String (Display_Name_For_Path (Target));

      if Is_Invalid_Path (Source) then
         Result.Status := File_Copy_Invalid_Source;
         Result.Error_Text := To_Unbounded_String ("invalid source");
         return Result;
      elsif Is_Invalid_Path (Target) then
         Result.Status := File_Copy_Invalid_Target;
         Result.Error_Text := To_Unbounded_String ("invalid target");
         return Result;
      end if;

      if not Ada.Directories.Exists (Source) then
         Result.Status := File_Copy_Source_Not_Found;
         Result.Error_Text := To_Unbounded_String ("source not found");
         return Result;
      elsif Ada.Directories.Kind (Source) = Ada.Directories.Directory then
         Result.Status := File_Copy_Source_Is_Directory;
         Result.Error_Text := To_Unbounded_String ("source is a directory");
         return Result;
      elsif Ada.Directories.Kind (Source) /= Ada.Directories.Ordinary_File then
         Result.Status := File_Copy_Invalid_Source;
         Result.Error_Text := To_Unbounded_String ("invalid source");
         return Result;
      end if;

      if Ada.Directories.Exists (Target) then
         Result.Status := File_Copy_Target_Exists;
         Result.Error_Text := To_Unbounded_String ("target exists");
         return Result;
      end if;

      Result.Source_Path := To_Unbounded_String
        (Canonical_Path_For_Existing_File (Source));

      Stream_IO.Open (Source_File, Stream_IO.In_File, To_String (Result.Source_Path));
      Stream_IO.Create (Target_File, Stream_IO.Out_File, Target);

      declare
         Buffer : Ada.Streams.Stream_Element_Array (1 .. 8192);
         Last   : Ada.Streams.Stream_Element_Offset;
      begin
         while not Stream_IO.End_Of_File (Source_File) loop
            Stream_IO.Read (Source_File, Buffer, Last);
            if Last >= Buffer'First then
               Stream_IO.Write (Target_File, Buffer (Buffer'First .. Last));
            end if;
         end loop;
      end;

      Stream_IO.Close (Source_File);
      Stream_IO.Close (Target_File);

      Result.Target_Path := To_Unbounded_String (Canonical_Path_For_Existing_File (Target));
      Result.Display_Name := To_Unbounded_String
        (Display_Name_For_Path (To_String (Result.Target_Path)));
      Result.Status := File_Copy_Ok;
      Result.Error_Text := Null_Unbounded_String;
      return Result;

   exception
      when Ada.Directories.Name_Error | Stream_IO.Name_Error =>
         if Stream_IO.Is_Open (Source_File) then
            Stream_IO.Close (Source_File);
         end if;
         if Stream_IO.Is_Open (Target_File) then
            Stream_IO.Close (Target_File);
         end if;
         Result.Status := File_Copy_Error;
         Result.Error_Text := To_Unbounded_String ("copy error");
         return Result;
      when Ada.Directories.Use_Error | Stream_IO.Use_Error =>
         if Stream_IO.Is_Open (Source_File) then
            Stream_IO.Close (Source_File);
         end if;
         if Stream_IO.Is_Open (Target_File) then
            Stream_IO.Close (Target_File);
         end if;
         Result.Status := File_Copy_Permission_Denied;
         Result.Error_Text := To_Unbounded_String ("permission denied");
         return Result;
      when others =>
         if Stream_IO.Is_Open (Source_File) then
            Stream_IO.Close (Source_File);
         end if;
         if Stream_IO.Is_Open (Target_File) then
            Stream_IO.Close (Target_File);
         end if;
         Result.Status := File_Copy_Error;
         Result.Error_Text := To_Unbounded_String ("copy error");
         return Result;
   end Copy_File;

   function Rename_File
     (Source : String;
      Target : String) return File_Rename_Result
   is
      Result  : File_Rename_Result;
      Success : Boolean := False;
   begin
      Result.Source_Path := To_Unbounded_String (Source);
      Result.Target_Path := To_Unbounded_String (Target);
      Result.Display_Name := To_Unbounded_String (Display_Name_For_Path (Target));

      if Is_Invalid_Path (Source) then
         Result.Status := File_Rename_Invalid_Source;
         Result.Error_Text := To_Unbounded_String ("invalid source");
         return Result;
      elsif Is_Invalid_Path (Target) then
         Result.Status := File_Rename_Invalid_Target;
         Result.Error_Text := To_Unbounded_String ("invalid target");
         return Result;
      end if;

      if not Ada.Directories.Exists (Source) then
         Result.Status := File_Rename_Source_Not_Found;
         Result.Error_Text := To_Unbounded_String ("source not found");
         return Result;
      elsif Ada.Directories.Kind (Source) = Ada.Directories.Directory then
         Result.Status := File_Rename_Source_Is_Directory;
         Result.Error_Text := To_Unbounded_String ("source is a directory");
         return Result;
      elsif Ada.Directories.Kind (Source) /= Ada.Directories.Ordinary_File then
         Result.Status := File_Rename_Invalid_Source;
         Result.Error_Text := To_Unbounded_String ("invalid source");
         return Result;
      end if;

      if Ada.Directories.Exists (Target) then
         Result.Status := File_Rename_Target_Exists;
         Result.Error_Text := To_Unbounded_String ("target exists");
         return Result;
      end if;

      GNAT.OS_Lib.Rename_File (Source, Target, Success);
      if not Success then
         Result.Status := File_Rename_Error;
         Result.Error_Text := To_Unbounded_String ("rename error");
         return Result;
      end if;

      Result.Target_Path := To_Unbounded_String (Canonical_Path_For_Existing_File (Target));
      Result.Display_Name := To_Unbounded_String
        (Display_Name_For_Path (To_String (Result.Target_Path)));
      Result.Status := File_Rename_Ok;
      Result.Error_Text := Null_Unbounded_String;
      return Result;

   exception
      when Ada.Directories.Name_Error =>
         Result.Status := File_Rename_Invalid_Target;
         Result.Error_Text := To_Unbounded_String ("invalid target");
         return Result;
      when Ada.Directories.Use_Error =>
         Result.Status := File_Rename_Permission_Denied;
         Result.Error_Text := To_Unbounded_String ("permission denied");
         return Result;
      when others =>
         Result.Status := File_Rename_Error;
         Result.Error_Text := To_Unbounded_String ("rename error");
         return Result;
   end Rename_File;


   function Move_File
     (Source : String;
      Target : String) return File_Move_Result
   is
      Result  : File_Move_Result;
      Success : Boolean := False;
   begin
      Result.Source_Path := To_Unbounded_String (Source);
      Result.Target_Path := To_Unbounded_String (Target);
      Result.Display_Name := To_Unbounded_String (Display_Name_For_Path (Target));

      if Is_Invalid_Path (Source) then
         Result.Status := File_Move_Invalid_Source;
         Result.Error_Text := To_Unbounded_String ("invalid source");
         return Result;
      elsif Is_Invalid_Path (Target) then
         Result.Status := File_Move_Invalid_Target;
         Result.Error_Text := To_Unbounded_String ("invalid target");
         return Result;
      end if;

      if not Ada.Directories.Exists (Source) then
         Result.Status := File_Move_Source_Not_Found;
         Result.Error_Text := To_Unbounded_String ("source not found");
         return Result;
      elsif Ada.Directories.Kind (Source) = Ada.Directories.Directory then
         Result.Status := File_Move_Source_Is_Directory;
         Result.Error_Text := To_Unbounded_String ("source is a directory");
         return Result;
      elsif Ada.Directories.Kind (Source) /= Ada.Directories.Ordinary_File then
         Result.Status := File_Move_Invalid_Source;
         Result.Error_Text := To_Unbounded_String ("invalid source");
         return Result;
      end if;

      if Ada.Directories.Exists (Target) then
         Result.Status := File_Move_Target_Exists;
         Result.Error_Text := To_Unbounded_String ("target exists");
         return Result;
      end if;

      GNAT.OS_Lib.Rename_File (Source, Target, Success);
      if not Success then
         Result.Status := File_Move_Error;
         Result.Error_Text := To_Unbounded_String ("move error");
         return Result;
      end if;

      Result.Target_Path := To_Unbounded_String (Canonical_Path_For_Existing_File (Target));
      Result.Display_Name := To_Unbounded_String
        (Display_Name_For_Path (To_String (Result.Target_Path)));
      Result.Status := File_Move_Ok;
      Result.Error_Text := Null_Unbounded_String;
      return Result;

   exception
      when Ada.Directories.Name_Error =>
         Result.Status := File_Move_Invalid_Target;
         Result.Error_Text := To_Unbounded_String ("invalid target");
         return Result;
      when Ada.Directories.Use_Error =>
         Result.Status := File_Move_Permission_Denied;
         Result.Error_Text := To_Unbounded_String ("permission denied");
         return Result;
      when others =>
         Result.Status := File_Move_Error;
         Result.Error_Text := To_Unbounded_String ("move error");
         return Result;
   end Move_File;

   function Save_File
     (Path     : String;
      Contents : String) return File_Save_Result
   is
      F       : Stream_IO.File_Type;
      Result  : File_Save_Result;
      Temp    : Unbounded_String := Null_Unbounded_String;

      procedure Close_Temp_Best_Effort is
      begin
         if Stream_IO.Is_Open (F) then
            Stream_IO.Close (F);
         end if;
      exception
         when others =>
            null;
      end Close_Temp_Best_Effort;

      procedure Remove_Temp_Best_Effort is
      begin
         Close_Temp_Best_Effort;
         if Length (Temp) > 0 and then Ada.Directories.Exists (To_String (Temp)) then
            Ada.Directories.Delete_File (To_String (Temp));
         end if;
      exception
         when others =>
            null;
      end Remove_Temp_Best_Effort;

      function Temp_Path_For (Target : String) return String is
         Dir  : constant String := Ada.Directories.Containing_Directory (Target);
         Base : constant String := Ada.Directories.Simple_Name (Target);
      begin
         return Ada.Directories.Compose (Dir, "." & Base & ".editor-save.tmp");
      exception
         when others =>
            return Target & ".editor-save.tmp";
      end Temp_Path_For;

   begin
      Result.Path := To_Unbounded_String (Path);
      Result.Display_Name := To_Unbounded_String (Display_Name_For_Path (Path));

      if Is_Invalid_Path (Path) then
         Result.Status := File_Save_Invalid_Path;
         Result.Error_Text := To_Unbounded_String ("invalid path");
         return Result;
      end if;

      if Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Directory
      then
         Result.Status := File_Save_Is_Directory;
         Result.Error_Text := To_Unbounded_String ("path is a directory");
         return Result;
      elsif Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File
      then
         Result.Status := File_Save_Invalid_Path;
         Result.Error_Text := To_Unbounded_String ("not a regular file");
         return Result;
      end if;

      declare
         Parent : constant String := Ada.Directories.Containing_Directory (Path);
      begin
         if Parent'Length > 0 and then not Ada.Directories.Exists (Parent) then
            Result.Status := File_Save_Parent_Unavailable;
            Result.Error_Text := To_Unbounded_String ("parent directory is unavailable");
            return Result;
         elsif Parent'Length > 0
           and then Ada.Directories.Kind (Parent) /= Ada.Directories.Directory
         then
            Result.Status := File_Save_Parent_Unavailable;
            Result.Error_Text := To_Unbounded_String ("parent directory is unavailable");
            return Result;
         end if;
      exception
         when others =>
            Result.Status := File_Save_Parent_Unavailable;
            Result.Error_Text := To_Unbounded_String ("parent directory is unavailable");
            return Result;
      end;

      Temp := To_Unbounded_String (Temp_Path_For (Path));
      Remove_Temp_Best_Effort;
      Stream_IO.Create (F, Stream_IO.Out_File, To_String (Temp));

      if Contents'Length > 0 then
         declare
            Raw : Ada.Streams.Stream_Element_Array
              (1 .. Ada.Streams.Stream_Element_Offset (Contents'Length));
         begin
            for J in Contents'Range loop
               Raw (Ada.Streams.Stream_Element_Offset (J - Contents'First + 1)) :=
                 Ada.Streams.Stream_Element (Character'Pos (Contents (J)));
            end loop;

            Stream_IO.Write (F, Raw);
         end;
      end if;

      Stream_IO.Close (F);

      declare
         Success : Boolean := False;
      begin
         GNAT.OS_Lib.Rename_File (To_String (Temp), Path, Success);
         if not Success then
            Remove_Temp_Best_Effort;
            Result.Status := File_Save_Write_Error;
            Result.Error_Text := To_Unbounded_String ("write error");
            return Result;
         end if;
      exception
         when Ada.Directories.Use_Error =>
            Remove_Temp_Best_Effort;
            Result.Status := File_Save_Permission_Denied;
            Result.Error_Text := To_Unbounded_String ("permission denied");
            return Result;
         when others =>
            Remove_Temp_Best_Effort;
            Result.Status := File_Save_Write_Error;
            Result.Error_Text := To_Unbounded_String ("write error");
            return Result;
      end;

      Remove_Temp_Best_Effort;
      Result.Path := To_Unbounded_String (Canonical_Path_For_Existing_File (Path));
      Result.Display_Name := To_Unbounded_String
        (Display_Name_For_Path (To_String (Result.Path)));
      Result.Status := File_Save_Ok;
      Result.Error_Text := Null_Unbounded_String;
      return Result;

   exception
      when Ada.Directories.Name_Error | Stream_IO.Name_Error =>
         Remove_Temp_Best_Effort;
         Result.Status := File_Save_Invalid_Path;
         Result.Error_Text := To_Unbounded_String ("invalid path");
         return Result;

      when Ada.Directories.Use_Error | Stream_IO.Use_Error =>
         Remove_Temp_Best_Effort;
         Result.Status := File_Save_Permission_Denied;
         Result.Error_Text := To_Unbounded_String ("permission denied");
         return Result;

      when others =>
         Remove_Temp_Best_Effort;
         Result.Status := File_Save_Write_Error;
         Result.Error_Text := To_Unbounded_String ("write error");
         return Result;
   end Save_File;

   function Load_File
     (Path : String;
      S    : in out Editor.State.State_Type) return File_Status
   is
      Result : constant File_Open_Result := Open_File (Path);
   begin
      if not Is_Success (Result) then
         return Status_To_File_Status (Result.Status);
      end if;

      Editor.State.Replace_Buffer_Contents (S, To_String (Result.Contents));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Result.Path;
      S.File_Info.Display_Name := Result.Display_Name;
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      S.File_Info.Last_Save_Failed := False;
      S.File_Info.Last_Reload_Failed := False;
      S.File_Info.Last_Revert_Failed := False;
      S.File_Info.Missing_Target_Surfaced := False;
      S.File_Info.Unreadable_Target_Surfaced := False;
      S.File_Info.Unwritable_Target_Surfaced := False;
      S.File_Info.External_Change_Surfaced := False;
      declare
         Found : Boolean := False;
         Label : constant String := Current_Token_Label (To_String (Result.Path), Found);
      begin
         S.File_Info.File_Token_Known := Found;
         S.File_Info.File_Token_Label := To_Unbounded_String (Label);
      end;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.View.Reset_Scroll;
      return Ok;
   end Load_File;

   function Save_File
     (Path : String;
      S    : in out Editor.State.State_Type) return File_Status
   is
      Result : constant File_Save_Result :=
        Save_File (Path, Editor.State.Current_Text (S));
   begin
      if Is_Success (Result) then
         S.File_Info.Has_Path := True;
         S.File_Info.Path := Result.Path;
         S.File_Info.Display_Name := Result.Display_Name;
         S.File_Info.Dirty := False;
         S.File_Info.Baseline_Valid := True;
         S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
         S.File_Info.Last_Save_Failed := False;
         S.File_Info.Last_Reload_Failed := False;
         S.File_Info.Last_Revert_Failed := False;
         S.File_Info.Missing_Target_Surfaced := False;
         S.File_Info.Unreadable_Target_Surfaced := False;
         S.File_Info.Unwritable_Target_Surfaced := False;
         S.File_Info.External_Change_Surfaced := False;
         declare
            Found : Boolean := False;
            Label : constant String := Current_Token_Label (To_String (Result.Path), Found);
         begin
            S.File_Info.File_Token_Known := Found;
            S.File_Info.File_Token_Label := To_Unbounded_String (Label);
         end;
         Editor.State.Reset_Dirty_Line_Baseline (S);
      end if;

      return Status_To_File_Status (Result.Status);
   end Save_File;

end Editor.Files;
