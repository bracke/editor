with Editor.Workspace_Persistence;
with Ada.Strings.Unbounded;

package Editor.Workspace_Persistence.Parsing is

   function Has_Malformed_Metadata_Separators
     (Line      : String;
      First_Sep : Natural) return Boolean;
   procedure Report_Unsupported_Field
     (Snapshot : in out Workspace_Snapshot;
      Status   : in out Workspace_Persistence_Status;
      Line_No  : Natural;
      Text     : String);
   procedure Parse_Project_Reference_Line
     (Line     : String;
      Line_No  : Natural;
      Snapshot : in out Workspace_Snapshot;
      Status   : in out Workspace_Persistence_Status);
   procedure Parse_Open_File_Line
     (Line     : String;
      Line_No  : Natural;
      Snapshot : in out Workspace_Snapshot;
      Status   : in out Workspace_Persistence_Status);
   procedure Load_From_File
     (Path     : String;
      Snapshot : out Workspace_Snapshot;
      Status   : out Workspace_Persistence_Status);


end Editor.Workspace_Persistence.Parsing;
