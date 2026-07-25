with Editor.Workspace_Persistence;
with Ada.Strings.Unbounded;

package Editor.Workspace_Persistence.File_IO is

   function Session_File_Path
     (Project_Root : String) return String;

   function Session_File_Status
     (Project_Root : String) return Workspace_Session_File_Status;

   --  Return True only when the configured session file is present and
   --  cheaply readable.  This function has no editor-state side effects.
   --  @param Project_Root active project root path.
   --  @return True when a session file can be offered to the user.
   function Workspace_State_Exists
     (Project_Root : String) return Boolean;

   function Is_Session_File_Path_For_Project
     (Project_Root : String;
      Path         : String) return Boolean;

   procedure Write_Snapshot_To_File
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status);
   procedure Save_To_File
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status);

   --  Save Snapshot using a temporary file in the target directory and replace
   --  the target on success where supported by the host filesystem.
   --  @param Snapshot Snapshot to persist.
   --  @param Path Target session file path.
   --  @param Status Persistence status.
   procedure Save_To_File_Atomically
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status);


end Editor.Workspace_Persistence.File_IO;
