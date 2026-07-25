with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Editor.Workspace_Persistence.Text_Format; use Editor.Workspace_Persistence.Text_Format;
with Editor.Workspace_Persistence.Path_Validation; use Editor.Workspace_Persistence.Path_Validation;
with Editor.Workspace_Persistence.Snapshot_Model; use Editor.Workspace_Persistence.Snapshot_Model;
with Editor.Workspace_Persistence.Parsing; use Editor.Workspace_Persistence.Parsing;
with Editor.Workspace_Persistence.Audits; use Editor.Workspace_Persistence.Audits;

package body Editor.Workspace_Persistence.File_IO is

   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;

   function Session_File_Path
     (Project_Root : String) return String
   is
   begin
      return Ada.Directories.Compose
        (Ada.Directories.Compose (Project_Root, ".editor"), "session");
   end Session_File_Path;


   function Session_File_Status
     (Project_Root : String) return Workspace_Session_File_Status
   is
      Path : constant String := Session_File_Path (Project_Root);
      File : Ada.Text_IO.File_Type;
   begin
      if Project_Root'Length = 0 or else not Ada.Directories.Exists (Path) then
         return Session_File_Missing;
      end if;

      if Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File then
         return Session_File_Unreadable;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      Ada.Text_IO.Close (File);
      return Session_File_Present;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return Session_File_Unreadable;
   end Session_File_Status;

   function Workspace_State_Exists
     (Project_Root : String) return Boolean
   is
   begin
      return Session_File_Status (Project_Root) = Session_File_Present;
   end Workspace_State_Exists;

   function Is_Session_File_Path_For_Project
     (Project_Root : String;
      Path         : String) return Boolean
   is
   begin
      return Comparable_Path (Path) = Comparable_Path (Session_File_Path (Project_Root));
   exception
      when others =>
         return False;
   end Is_Session_File_Path_For_Project;

   procedure Write_Snapshot_To_File
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status)
   is
      File : Ada.Text_IO.File_Type;
      Copy : Workspace_Snapshot := Snapshot;
   begin
      Status := Workspace_Persistence_Ok;
      Normalize (Copy);

      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Serialized_Text (Copy));
      --  Settings-owned data, including the active theme, is intentionally
      --  excluded from the workspace session format.  Workspace persistence
      --  records structural session state only.
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Status := Workspace_Persistence_Write_Error;
   end Write_Snapshot_To_File;

   procedure Save_To_File
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status)
   is
   begin
      Save_To_File_Atomically (Snapshot, Path, Status);
   end Save_To_File;

   procedure Save_To_File_Atomically
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status)
   is
      Dir      : constant String := Ada.Directories.Containing_Directory (Path);
      Base     : constant String := Ada.Directories.Simple_Name (Path);
      Temp     : constant String := Ada.Directories.Compose
        (Dir, "." & Base & ".tmp");

      procedure Remove_Temp_Best_Effort is
      begin
         if Ada.Directories.Exists (Temp) then
            Ada.Directories.Delete_File (Temp);
         end if;
      exception
         when others =>
            null;
      end Remove_Temp_Best_Effort;
   begin
      Status := Workspace_Persistence_Ok;
      if Dir'Length > 0 and then not Ada.Directories.Exists (Dir) then
         Ada.Directories.Create_Path (Dir);
      end if;

      Remove_Temp_Best_Effort;
      Write_Snapshot_To_File (Snapshot, Temp, Status);
      if Status /= Workspace_Persistence_Ok then
         Remove_Temp_Best_Effort;
         return;
      end if;

      declare
         Success : Boolean := False;
      begin
         GNAT.OS_Lib.Rename_File (Temp, Path, Success);
         if not Success then
            Remove_Temp_Best_Effort;
            Status := Workspace_Persistence_Write_Error;
            return;
         end if;
      exception
         when others =>
            Remove_Temp_Best_Effort;
            Status := Workspace_Persistence_Write_Error;
            return;
      end;

      Remove_Temp_Best_Effort;
      Status := Workspace_Persistence_Ok;
   exception
      when others =>
         Status := Workspace_Persistence_Write_Error;
   end Save_To_File_Atomically;


end Editor.Workspace_Persistence.File_IO;
