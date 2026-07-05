with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Workspace_Persistence is
   type Workspace_Persistence_Status is
     (Workspace_Persistence_Ok,
      Workspace_Persistence_Not_Found,
      Workspace_Persistence_Invalid_Format,
      Workspace_Persistence_Unsupported_Version,
      Workspace_Persistence_Read_Error,
      Workspace_Persistence_Write_Error,
      Workspace_Persistence_Partial_Restore);

   type Workspace_Lifecycle_Config is record
      Auto_Restore_On_Project_Open : Boolean := False;
      Report_Available_Session_On_Project_Open : Boolean := True;
      Save_On_Project_Close : Boolean := False;
   end record;

   Default_Workspace_Lifecycle_Config : constant Workspace_Lifecycle_Config :=
     (Auto_Restore_On_Project_Open => False,
      Report_Available_Session_On_Project_Open => True,
      Save_On_Project_Close => False);

   type Workspace_Session_File_Status is
     (Session_File_Missing,
      Session_File_Present,
      Session_File_Unreadable);

   type Workspace_Diagnostic_Kind is
     (Malformed_Line,
      Unknown_Section,
      Unsupported_Key,
      Invalid_Path,
      Duplicate_Path,
      Missing_File,
      Missing_Directory,
      Invalid_Number,
      Invalid_Panel_Value);

   type Workspace_Diagnostic is record
      Kind        : Workspace_Diagnostic_Kind := Malformed_Line;
      Line_Number : Natural := 0;
      Text        : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Workspace_Restore_Summary is record
      Files_Requested      : Natural := 0;
      Files_Restored       : Natural := 0;
      Files_Skipped        : Natural := 0;
      Expansions_Requested : Natural := 0;
      Expansions_Restored  : Natural := 0;
      Expansions_Skipped   : Natural := 0;
      Panel_Values_Clamped : Natural := 0;
   end record;

   type Workspace_Restore_Audit is record
      Snapshots_Equivalent      : Boolean := False;
      Runtime_State_Excluded    : Boolean := False;
      Restore_Counts_Coherent   : Boolean := False;
      Continuity_State_Restored : Boolean := False;
      Safe                      : Boolean := False;
   end record;

   type Workspace_File_Entry is record
      Path                : Ada.Strings.Unbounded.Unbounded_String;
      Is_Project_Relative : Boolean := True;
      Cursor_Row          : Natural := 0;
      Cursor_Column       : Natural := 0;
      View_First_Row      : Natural := 0;
   end record;

   type Bottom_Content_Id is
     (Workspace_Problems_Content,
      Workspace_Search_Results_Content);

   type Workspace_Feature_Panel_Id is
     (Workspace_Outline_Feature,
      Workspace_Messages_Feature,
      Workspace_Search_Results_Feature,
      Workspace_Diagnostics_Feature);

   type Workspace_Quick_Open_File_Kind_Filter is
     (Workspace_Quick_Open_All_Files,
      Workspace_Quick_Open_Ada_Files,
      Workspace_Quick_Open_Test_Files,
      Workspace_Quick_Open_Doc_Files,
      Workspace_Quick_Open_Other_Files);

   type Workspace_Snapshot is private;

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


   function Session_File_Path
     (Project_Root : String) return String;

   function Session_File_Path_For_Project
     (Project_Root : String) return String renames Session_File_Path;

   --  Cheaply classify the configured session file for Project_Root.
   --  This helper checks only path existence/readability metadata; full
   --  parsing and validation remain the responsibility of Load_From_File.
   --  @param Project_Root active project root path.
   --  @return missing, present, or unreadable session-file status.
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

   function Is_Safe_Project_Relative_Path
     (Path : String) return Boolean;

   function Normalize_Project_Relative_Path
     (Path  : String;
      Valid : out Boolean) return String;

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

   function Audit_Serialized_Buffer_Persistence
     (Serialized_Workspace : String) return Workspace_Buffer_Persistence_Audit;

   function Audit_Buffer_Persistence
     (Snapshot : Workspace_Snapshot) return Workspace_Buffer_Persistence_Audit;

   function Restore_Details_Label
     (Summary : Workspace_Restore_Summary) return String;

   function Audit_Restore_Roundtrip
     (Before  : Workspace_Snapshot;
      After   : Workspace_Snapshot;
      Summary : Workspace_Restore_Summary) return Workspace_Restore_Audit;

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

   procedure Load_From_File
     (Path     : String;
      Snapshot : out Workspace_Snapshot;
      Status   : out Workspace_Persistence_Status);

private
   package File_Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Workspace_File_Entry);

   package String_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String,
      "="          => Ada.Strings.Unbounded."=");

   package Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Workspace_Diagnostic);

   type Workspace_Snapshot is record
      Format_Version : Natural := 1;
      Has_Root       : Boolean := False;
      Root           : Ada.Strings.Unbounded.Unbounded_String;
      Open_Files     : File_Entry_Vectors.Vector;
      Open_File_Requests : Natural := 0;
      Has_Active     : Boolean := False;
      Active_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Active_Rel     : Boolean := True;
      Expanded_Paths : String_Vectors.Vector;
      File_Tree_Visible : Boolean := True;
      File_Tree_Width   : Natural := 28;
      Bottom_Visible    : Boolean := False;
      Bottom_Height     : Natural := 8;
      Bottom_Content    : Bottom_Content_Id := Workspace_Problems_Content;
      Has_Recent_Project : Boolean := False;
      Recent_Project     : Ada.Strings.Unbounded.Unbounded_String;
      Quick_Open_Scope   : Ada.Strings.Unbounded.Unbounded_String;
      Quick_Open_Filter  : Workspace_Quick_Open_File_Kind_Filter :=
        Workspace_Quick_Open_All_Files;
      Feature_Panel_Visible : Boolean := False;
      Active_Feature_Panel  : Workspace_Feature_Panel_Id :=
        Workspace_Outline_Feature;
      Diagnostics       : Diagnostic_Vectors.Vector;
   end record;
end Editor.Workspace_Persistence;
