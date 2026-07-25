with Editor.Workspace_Persistence.Text_Format;
with Editor.Workspace_Persistence.Path_Validation;
with Editor.Workspace_Persistence.Snapshot_Model;
with Editor.Workspace_Persistence.Parsing;
with Editor.Workspace_Persistence.File_IO;
with Editor.Workspace_Persistence.Audits;

package body Editor.Workspace_Persistence is

   procedure Clear
     (Snapshot : in out Workspace_Snapshot)
     renames Editor.Workspace_Persistence.Snapshot_Model.Clear;

   function Version
     (Snapshot : Workspace_Snapshot) return Natural
     renames Editor.Workspace_Persistence.Snapshot_Model.Version;

   procedure Set_Project_Root
     (Snapshot : in out Workspace_Snapshot;
      Path     : String)
     renames Editor.Workspace_Persistence.Snapshot_Model.Set_Project_Root;

   function Has_Project_Root
     (Snapshot : Workspace_Snapshot) return Boolean
     renames Editor.Workspace_Persistence.Snapshot_Model.Has_Project_Root;

   function Project_Root
     (Snapshot : Workspace_Snapshot) return String
     renames Editor.Workspace_Persistence.Snapshot_Model.Project_Root;

   procedure Add_Open_File
     (Snapshot : in out Workspace_Snapshot;
      Item    : Workspace_File_Entry)
     renames Editor.Workspace_Persistence.Snapshot_Model.Add_Open_File;

   function Open_File_Count
     (Snapshot : Workspace_Snapshot) return Natural
     renames Editor.Workspace_Persistence.Snapshot_Model.Open_File_Count;

   function Open_File_Request_Count
     (Snapshot : Workspace_Snapshot) return Natural
     renames Editor.Workspace_Persistence.Snapshot_Model.Open_File_Request_Count;

   function Open_File
     (Snapshot : Workspace_Snapshot;
      Index    : Positive) return Workspace_File_Entry
     renames Editor.Workspace_Persistence.Snapshot_Model.Open_File;

   procedure Set_Active_File_Path
     (Snapshot            : in out Workspace_Snapshot;
      Path                : String;
      Is_Project_Relative : Boolean := True)
     renames Editor.Workspace_Persistence.Snapshot_Model.Set_Active_File_Path;

   function Has_Active_File_Path
     (Snapshot : Workspace_Snapshot) return Boolean
     renames Editor.Workspace_Persistence.Snapshot_Model.Has_Active_File_Path;

   function Active_File_Path
     (Snapshot : Workspace_Snapshot) return String
     renames Editor.Workspace_Persistence.Snapshot_Model.Active_File_Path;

   function Active_File_Is_Project_Relative
     (Snapshot : Workspace_Snapshot) return Boolean
     renames Editor.Workspace_Persistence.Snapshot_Model.Active_File_Is_Project_Relative;

   procedure Add_Expanded_File_Tree_Path
     (Snapshot : in out Workspace_Snapshot;
      Path     : String)
     renames Editor.Workspace_Persistence.Snapshot_Model.Add_Expanded_File_Tree_Path;

   function Expanded_File_Tree_Path_Count
     (Snapshot : Workspace_Snapshot) return Natural
     renames Editor.Workspace_Persistence.Snapshot_Model.Expanded_File_Tree_Path_Count;

   function Expanded_File_Tree_Path
     (Snapshot : Workspace_Snapshot;
      Index    : Positive) return String
     renames Editor.Workspace_Persistence.Snapshot_Model.Expanded_File_Tree_Path;

   procedure Set_File_Tree_Panel
     (Snapshot : in out Workspace_Snapshot;
      Visible  : Boolean;
      Width    : Natural)
     renames Editor.Workspace_Persistence.Snapshot_Model.Set_File_Tree_Panel;

   function File_Tree_Panel_Visible
     (Snapshot : Workspace_Snapshot) return Boolean
     renames Editor.Workspace_Persistence.Snapshot_Model.File_Tree_Panel_Visible;

   function File_Tree_Panel_Width
     (Snapshot : Workspace_Snapshot) return Natural
     renames Editor.Workspace_Persistence.Snapshot_Model.File_Tree_Panel_Width;

   procedure Set_Bottom_Panel
     (Snapshot : in out Workspace_Snapshot;
      Visible  : Boolean;
      Height   : Natural;
      Content  : Bottom_Content_Id)
     renames Editor.Workspace_Persistence.Snapshot_Model.Set_Bottom_Panel;

   function Bottom_Panel_Visible
     (Snapshot : Workspace_Snapshot) return Boolean
     renames Editor.Workspace_Persistence.Snapshot_Model.Bottom_Panel_Visible;

   function Bottom_Panel_Height
     (Snapshot : Workspace_Snapshot) return Natural
     renames Editor.Workspace_Persistence.Snapshot_Model.Bottom_Panel_Height;

   function Active_Bottom_Content
     (Snapshot : Workspace_Snapshot) return Bottom_Content_Id
     renames Editor.Workspace_Persistence.Snapshot_Model.Active_Bottom_Content;

   procedure Set_Recent_Project_Path
     (Snapshot : in out Workspace_Snapshot;
      Path     : String)
     renames Editor.Workspace_Persistence.Snapshot_Model.Set_Recent_Project_Path;

   function Has_Recent_Project_Path
     (Snapshot : Workspace_Snapshot) return Boolean
     renames Editor.Workspace_Persistence.Snapshot_Model.Has_Recent_Project_Path;

   function Recent_Project_Path
     (Snapshot : Workspace_Snapshot) return String
     renames Editor.Workspace_Persistence.Snapshot_Model.Recent_Project_Path;

   procedure Set_Quick_Open_Path_Scope
     (Snapshot : in out Workspace_Snapshot;
      Scope    : String)
     renames Editor.Workspace_Persistence.Snapshot_Model.Set_Quick_Open_Path_Scope;

   function Quick_Open_Path_Scope
     (Snapshot : Workspace_Snapshot) return String
     renames Editor.Workspace_Persistence.Snapshot_Model.Quick_Open_Path_Scope;

   procedure Set_Quick_Open_File_Kind_Filter
     (Snapshot : in out Workspace_Snapshot;
      Filter   : Workspace_Quick_Open_File_Kind_Filter)
     renames Editor.Workspace_Persistence.Snapshot_Model.Set_Quick_Open_File_Kind_Filter;

   function Quick_Open_File_Kind_Filter
     (Snapshot : Workspace_Snapshot)
      return Workspace_Quick_Open_File_Kind_Filter
     renames Editor.Workspace_Persistence.Snapshot_Model.Quick_Open_File_Kind_Filter;

   procedure Set_Feature_Panel
     (Snapshot       : in out Workspace_Snapshot;
      Visible        : Boolean;
      Active_Feature : Workspace_Feature_Panel_Id)
     renames Editor.Workspace_Persistence.Snapshot_Model.Set_Feature_Panel;

   function Feature_Panel_Visible
     (Snapshot : Workspace_Snapshot) return Boolean
     renames Editor.Workspace_Persistence.Snapshot_Model.Feature_Panel_Visible;

   function Active_Feature_Panel
     (Snapshot : Workspace_Snapshot) return Workspace_Feature_Panel_Id
     renames Editor.Workspace_Persistence.Snapshot_Model.Active_Feature_Panel;

   function Session_File_Path
     (Project_Root : String) return String
     renames Editor.Workspace_Persistence.File_IO.Session_File_Path;

   function Session_File_Status
     (Project_Root : String) return Workspace_Session_File_Status
     renames Editor.Workspace_Persistence.File_IO.Session_File_Status;

   function Workspace_State_Exists
     (Project_Root : String) return Boolean
     renames Editor.Workspace_Persistence.File_IO.Workspace_State_Exists;

   function Is_Session_File_Path_For_Project
     (Project_Root : String;
      Path         : String) return Boolean
     renames Editor.Workspace_Persistence.File_IO.Is_Session_File_Path_For_Project;

   function Is_Safe_Project_Relative_Path
     (Path : String) return Boolean
     renames Editor.Workspace_Persistence.Path_Validation.Is_Safe_Project_Relative_Path;

   function Normalize_Project_Relative_Path
     (Path  : String;
      Valid : out Boolean) return String
     renames Editor.Workspace_Persistence.Path_Validation.Normalize_Project_Relative_Path;

   procedure Normalize
     (Snapshot : in out Workspace_Snapshot)
     renames Editor.Workspace_Persistence.Snapshot_Model.Normalize;

   function Equivalent
     (Left  : Workspace_Snapshot;
      Right : Workspace_Snapshot) return Boolean
     renames Editor.Workspace_Persistence.Snapshot_Model.Equivalent;

   function Debug_Summary
     (Snapshot : Workspace_Snapshot) return String
     renames Editor.Workspace_Persistence.Snapshot_Model.Debug_Summary;

   function Serialized_Text
     (Snapshot : Workspace_Snapshot) return String
     renames Editor.Workspace_Persistence.Snapshot_Model.Serialized_Text;

   function Audit_Serialized_Buffer_Persistence
     (Serialized_Workspace : String) return Workspace_Buffer_Persistence_Audit
     renames Editor.Workspace_Persistence.Audits.Audit_Serialized_Buffer_Persistence;

   function Audit_Buffer_Persistence
     (Snapshot : Workspace_Snapshot) return Workspace_Buffer_Persistence_Audit
     renames Editor.Workspace_Persistence.Audits.Audit_Buffer_Persistence;

   function Restore_Details_Label
     (Summary : Workspace_Restore_Summary) return String
     renames Editor.Workspace_Persistence.Audits.Restore_Details_Label;

   function Audit_Restore_Roundtrip
     (Before  : Workspace_Snapshot;
      After   : Workspace_Snapshot;
      Summary : Workspace_Restore_Summary) return Workspace_Restore_Audit
     renames Editor.Workspace_Persistence.Audits.Audit_Restore_Roundtrip;

   function Diagnostic_Count
     (Snapshot : Workspace_Snapshot) return Natural
     renames Editor.Workspace_Persistence.Snapshot_Model.Diagnostic_Count;

   function Diagnostic
     (Snapshot : Workspace_Snapshot;
      Index    : Positive) return Workspace_Diagnostic
     renames Editor.Workspace_Persistence.Snapshot_Model.Diagnostic;

   procedure Save_To_File
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status)
     renames Editor.Workspace_Persistence.File_IO.Save_To_File;

   procedure Save_To_File_Atomically
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status)
     renames Editor.Workspace_Persistence.File_IO.Save_To_File_Atomically;

   procedure Load_From_File
     (Path     : String;
      Snapshot : out Workspace_Snapshot;
      Status   : out Workspace_Persistence_Status)
     renames Editor.Workspace_Persistence.Parsing.Load_From_File;

end Editor.Workspace_Persistence;
