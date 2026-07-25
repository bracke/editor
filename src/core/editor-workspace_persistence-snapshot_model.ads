with Editor.Workspace_Persistence;
with Ada.Strings.Unbounded;

package Editor.Workspace_Persistence.Snapshot_Model is

   function Has_Open_File_Path
     (Snapshot : Workspace_Snapshot;
      Path     : String) return Boolean;
   function Has_Expanded_Path
     (Snapshot : Workspace_Snapshot;
      Path     : String) return Boolean;
   procedure Mark_Partial
     (Status : in out Workspace_Persistence_Status);
   procedure Add_Diagnostic
     (Snapshot : in out Workspace_Snapshot;
      Kind     : Workspace_Diagnostic_Kind;
      Line_No  : Natural;
      Text     : String);
   procedure Sort_Expanded_Paths (Snapshot : in out Workspace_Snapshot);
   procedure Clear
     (Snapshot : in out Workspace_Snapshot);

   function Version
     (Snapshot : Workspace_Snapshot) return Natural;

   procedure Set_Project_Root
     (Snapshot : in out Workspace_Snapshot;
      Path     : String);

   function Has_Project_Root
     (Snapshot : Workspace_Snapshot) return Boolean;

   function Project_Root
     (Snapshot : Workspace_Snapshot) return String;

   procedure Add_Open_File
     (Snapshot : in out Workspace_Snapshot;
      Item    : Workspace_File_Entry);

   function Open_File_Count
     (Snapshot : Workspace_Snapshot) return Natural;

   function Open_File_Request_Count
     (Snapshot : Workspace_Snapshot) return Natural;

   function Open_File
     (Snapshot : Workspace_Snapshot;
      Index    : Positive) return Workspace_File_Entry;

   procedure Set_Active_File_Path
     (Snapshot            : in out Workspace_Snapshot;
      Path                : String;
      Is_Project_Relative : Boolean := True);

   function Has_Active_File_Path
     (Snapshot : Workspace_Snapshot) return Boolean;

   function Active_File_Path
     (Snapshot : Workspace_Snapshot) return String;

   function Active_File_Is_Project_Relative
     (Snapshot : Workspace_Snapshot) return Boolean;

   procedure Add_Expanded_File_Tree_Path
     (Snapshot : in out Workspace_Snapshot;
      Path     : String);

   function Expanded_File_Tree_Path_Count
     (Snapshot : Workspace_Snapshot) return Natural;

   function Expanded_File_Tree_Path
     (Snapshot : Workspace_Snapshot;
      Index    : Positive) return String;

   procedure Set_File_Tree_Panel
     (Snapshot : in out Workspace_Snapshot;
      Visible  : Boolean;
      Width    : Natural);

   function File_Tree_Panel_Visible
     (Snapshot : Workspace_Snapshot) return Boolean;

   function File_Tree_Panel_Width
     (Snapshot : Workspace_Snapshot) return Natural;

   procedure Set_Bottom_Panel
     (Snapshot : in out Workspace_Snapshot;
      Visible  : Boolean;
      Height   : Natural;
      Content  : Bottom_Content_Id);

   function Bottom_Panel_Visible
     (Snapshot : Workspace_Snapshot) return Boolean;

   function Bottom_Panel_Height
     (Snapshot : Workspace_Snapshot) return Natural;

   function Active_Bottom_Content
     (Snapshot : Workspace_Snapshot) return Bottom_Content_Id;

   procedure Set_Recent_Project_Path
     (Snapshot : in out Workspace_Snapshot;
      Path     : String);

   function Has_Recent_Project_Path
     (Snapshot : Workspace_Snapshot) return Boolean;

   function Recent_Project_Path
     (Snapshot : Workspace_Snapshot) return String;

   procedure Set_Quick_Open_Path_Scope
     (Snapshot : in out Workspace_Snapshot;
      Scope    : String);

   function Quick_Open_Path_Scope
     (Snapshot : Workspace_Snapshot) return String;

   procedure Set_Quick_Open_File_Kind_Filter
     (Snapshot : in out Workspace_Snapshot;
      Filter   : Workspace_Quick_Open_File_Kind_Filter);

   function Quick_Open_File_Kind_Filter
     (Snapshot : Workspace_Snapshot)
      return Workspace_Quick_Open_File_Kind_Filter;

   procedure Set_Feature_Panel
     (Snapshot       : in out Workspace_Snapshot;
      Visible        : Boolean;
      Active_Feature : Workspace_Feature_Panel_Id);

   function Feature_Panel_Visible
     (Snapshot : Workspace_Snapshot) return Boolean;

   function Active_Feature_Panel
     (Snapshot : Workspace_Snapshot) return Workspace_Feature_Panel_Id;


   function Diagnostic_Count
     (Snapshot : Workspace_Snapshot) return Natural;

   function Diagnostic
     (Snapshot : Workspace_Snapshot;
      Index    : Positive) return Workspace_Diagnostic;

   --  Save Snapshot using the workspace persistence format.
   --  The implementation delegates to Save_To_File_Atomically so callers that
   --  still use the API receive the write-safety policy.
   --  @param Snapshot Snapshot to persist.
   --  @param Path Target session file path.
   --  @param Status Persistence status.
   procedure Normalize
     (Snapshot : in out Workspace_Snapshot);

   function Equivalent
     (Left  : Workspace_Snapshot;
      Right : Workspace_Snapshot) return Boolean;

   function Debug_Summary
     (Snapshot : Workspace_Snapshot) return String;


   type Workspace_Buffer_Persistence_Audit is record
      Runtime_Buffer_Id_Persisted   : Boolean := False;
      Active_Buffer_Id_Persisted    : Boolean := False;
      Selected_Buffer_Id_Persisted  : Boolean := False;
      Buffer_List_State_Persisted   : Boolean := False;
      Dirty_Text_Persisted          : Boolean := False;
      Scratch_Text_Persisted        : Boolean := False;
      Conflict_Token_Persisted      : Boolean := False;
      Close_Prompt_State_Persisted  : Boolean := False;
      Undo_Redo_Clipboard_Persisted : Boolean := False;
      Safe                          : Boolean := True;
   end record;

   function Serialized_Text
     (Snapshot : Workspace_Snapshot) return String;


end Editor.Workspace_Persistence.Snapshot_Model;
