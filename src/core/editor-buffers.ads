with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Buffer_Types;
use type Editor.Buffer_Types.Buffer_Id;
with Editor.History;
limited with Editor.State;
with Editor.View_Types;
with Editor.Dirty_Guards;
with Editor.Project;

package Editor.Buffers is

   subtype Buffer_Id is Editor.Buffer_Types.Buffer_Id;
   No_Buffer : constant Buffer_Id := Editor.Buffer_Types.No_Buffer;

   package Buffer_Id_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Buffer_Id);

   subtype File_Identity is Editor.State.File_State;
   subtype Buffer_State is Editor.State.State_Type;

   type Buffer_Registry is private;


   type Buffer_Ownership_Kind is
     (Buffer_Project_Owned,
      Buffer_Outside_Project,
      Buffer_Scratch_Unbacked,
      Buffer_Missing_Project_Context,
      Buffer_Unknown_File_Backed);

   type Buffer_Dirty_Category is
     (Buffer_Not_Dirty,
      Buffer_Dirty_Project_File,
      Buffer_Dirty_Outside_Project_File,
      Buffer_Dirty_Scratch,
      Buffer_Dirty_Missing_File,
      Buffer_Dirty_Conflicted_File,
      Buffer_Dirty_Unwritable_File);

   type Buffer_Close_Eligibility is
     (Buffer_Closable_Clean,
      Buffer_Requires_Dirty_Confirmation,
      Buffer_Requires_Save_As_Or_Discard,
      Buffer_Requires_Conflict_Resolution_Or_Discard,
      Buffer_Blocked_By_Pending_Confirmation,
      Buffer_Not_A_Real_Row);

   type Buffer_Workspace_Persistability is
     (Buffer_Persistable_File_Reference,
      Buffer_Not_Persistable_Scratch,
      Buffer_Not_Persistable_Invalid_Path,
      Buffer_Not_Persistable_Runtime_Only_Id,
      Buffer_Not_Persistable_Dirty_Text);

   type Buffer_Metadata_Snapshot is record
      Id                       : Buffer_Id := No_Buffer;
      Display_Label            : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_File_Path            : Boolean := False;
      File_Path                : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Scratch_Label        : Boolean := False;
      Scratch_Label            : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Project_Relative_Path : Boolean := False;
      Project_Relative_Path    : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Outside_Project_Path_Label : Boolean := False;
      Outside_Project_Path_Label : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Is_Active                : Boolean := False;
      Is_Selected              : Boolean := False;
      Is_Dirty                 : Boolean := False;
      Is_Clean                 : Boolean := True;
      Is_Scratch               : Boolean := False;
      Missing_Backing_File     : Boolean := False;
      External_Conflict        : Boolean := False;
      Stale_Backing_State      : Boolean := False;
      Unreadable               : Boolean := False;
      Unwritable               : Boolean := False;
      Ownership                : Buffer_Ownership_Kind := Buffer_Missing_Project_Context;
      Ownership_Label          : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Lifecycle_Status_Label   : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Dirty_Category           : Buffer_Dirty_Category := Buffer_Not_Dirty;
      Close_Eligibility        : Buffer_Close_Eligibility := Buffer_Not_A_Real_Row;
      Workspace_Persistability : Buffer_Workspace_Persistability := Buffer_Not_Persistable_Runtime_Only_Id;
   end record;

   type Buffer_Project_Lifecycle_Sets is record
      Project_Owned                 : Buffer_Id_Vectors.Vector;
      Project_Owned_Dirty           : Buffer_Id_Vectors.Vector;
      Project_Owned_Clean           : Buffer_Id_Vectors.Vector;
      Outside_Project               : Buffer_Id_Vectors.Vector;
      Scratch                       : Buffer_Id_Vectors.Vector;
      Project_Close_Affected        : Buffer_Id_Vectors.Vector;
      Project_Close_Unaffected      : Buffer_Id_Vectors.Vector;
   end record;

   type Buffer_Audit_Summary is record
      Buffer_Count                   : Natural := 0;
      Active_Buffer_Valid            : Boolean := True;
      Selected_Buffer_Valid          : Boolean := True;
      Project_Owned_Count            : Natural := 0;
      Outside_Project_Count          : Natural := 0;
      Scratch_Count                  : Natural := 0;
      Missing_Or_Conflicted_Count    : Natural := 0;
      Stale_Backing_State_Count      : Natural := 0;
      Lifecycle_Problem_Count        : Natural := 0;
      Project_Close_Affected_Count   : Natural := 0;
      Project_Close_Unaffected_Count : Natural := 0;
      Unreadable_Count               : Natural := 0;
      Unwritable_Count               : Natural := 0;
      Project_Owned_Clean_Count      : Natural := 0;
      Project_Owned_Dirty_Count      : Natural := 0;
      Outside_Project_Clean_Count    : Natural := 0;
      Outside_Project_Dirty_Count    : Natural := 0;
      Scratch_Clean_Count            : Natural := 0;
      Scratch_Dirty_Count            : Natural := 0;
      Close_Direct_Count             : Natural := 0;
      Close_Needs_Confirmation_Count : Natural := 0;
      Close_Needs_Save_As_Count      : Natural := 0;
      Close_Needs_Conflict_Count     : Natural := 0;
      Close_Blocked_Count            : Natural := 0;
      Dirty_Project_File_Count       : Natural := 0;
      Dirty_Outside_Project_Count    : Natural := 0;
      Dirty_Scratch_Count            : Natural := 0;
      Dirty_Missing_Count            : Natural := 0;
      Dirty_Conflicted_Count         : Natural := 0;
      Dirty_Unwritable_Count         : Natural := 0;
      Workspace_Persistable_Count    : Natural := 0;
      Workspace_Not_Persistable_Count : Natural := 0;
      Dirty_Project_Files_Summary_Label : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Dirty_Outside_Project_Summary_Label : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Dirty_Scratch_Summary_Label     : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Dirty_File_Conflict_Summary_Label : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Workspace_Persistability_Summary_Label : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Project_Lifecycle_Buffer_Set_Summary_Label : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Active_Runtime_Id_Persisted    : Boolean := False;
      Selected_Runtime_Id_Persisted  : Boolean := False;
      Buffer_List_State_Persisted    : Boolean := False;
      Dirty_Text_Persisted           : Boolean := False;
      Scratch_Text_Persisted         : Boolean := False;
      Conflict_Token_Persisted       : Boolean := False;
      Runtime_Buffer_Id_Persisted    : Boolean := False;
      Command_Or_Keybinding_Payload  : Boolean := False;
      Render_Mutation_Route          : Boolean := False;
      Metadata_Projection_Coherent   : Boolean := True;
      Workspace_Persistence_Safe     : Boolean := True;
      Command_Keybinding_Payloads_Clear : Boolean := True;
      Render_Boundary_Safe           : Boolean := True;
      Audit_Side_Effect_Free         : Boolean := True;
   end record;

   subtype Buffer_Summary is Editor.Buffer_Types.Buffer_Summary;

   function Create_Untitled_Buffer
     (Registry : in out Buffer_Registry) return Buffer_Id;

   function Add_Buffer_From_File
     (Registry     : in out Buffer_Registry;
      Path         : String;
      Display_Name : String;
      Contents     : String) return Buffer_Id;

   function Contains
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   function Active_Buffer
     (Registry : Buffer_Registry) return Buffer_Id;

   procedure Set_Active_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   function Count
     (Registry : Buffer_Registry) return Natural;

   function Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Summary_At
     (Registry : Buffer_Registry;
      Index    : Positive) return Buffer_Summary;

   function Summary_For
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Buffer_Summary;

   function Metadata_For
     (Registry   : Buffer_Registry;
      Project    : Editor.Project.Project_State;
      Id         : Buffer_Id;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Metadata_Snapshot;

   --  Phase 577 canonical ownership classifier.  This is the single public
   --  projection seam for deciding whether a buffer path is project-owned,
   --  outside-project, scratch/unbacked, missing-project-context, or unknown.
   --  It is derived only from the explicit Has_Path flag, the normalized path,
   --  and the active project root; it does not mutate registry/project state,
   --  does not probe the filesystem, and does not persist an ownership cache.
   function Classify_Buffer_Ownership
     (Has_Path : Boolean;
      Path     : String;
      Project  : Editor.Project.Project_State) return Buffer_Ownership_Kind;

   function Ownership_Label (Kind : Buffer_Ownership_Kind) return String;

   function Dirty_Category_Label (Kind : Buffer_Dirty_Category) return String;

   function Close_Eligibility_Label (Kind : Buffer_Close_Eligibility) return String;

   function Workspace_Persistability_Label
     (Kind : Buffer_Workspace_Persistability) return String;

   function Metadata_Label_Max_Length return Positive;

   function Audit_Buffers
     (Registry    : Buffer_Registry;
      Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Audit_Summary;

   function Buffer_Metadata_Lifecycle_Audit_Coherent
     (Registry    : Buffer_Registry;
      Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Boolean;

   --  Phase 577 deterministic project lifecycle sets.  The vectors preserve
   --  registry order and are derived from the same metadata ownership and dirty
   --  categorization used by Buffer List, dirty review, and audits.  They are
   --  transient process-local runtime handles for immediate lifecycle review
   --  only; callers must revalidate before mutation and must not persist them.
   function Project_Lifecycle_Buffer_Sets
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Buffer_Project_Lifecycle_Sets;

   function Project_Owned_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural;

   function Outside_Project_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural;

   function Scratch_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Project_Owned_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural;

   function Outside_Project_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural;

   function Scratch_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural;

   --  Phase 577 dirty-review bridge.  These helpers convert the canonical
   --  metadata/audit dirty categories into the Dirty_Guards summary used by
   --  close/project/workspace prompts.  They ensure those
   --  workflows do not independently re-infer dirty file/scratch/project
   --  membership from Buffer_Summary or raw paths.
   function Categorized_Dirty_Buffer_Summary
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Project_Lifecycle_Dirty_Buffer_Summary
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;


   function Is_Empty
     (Registry : Buffer_Registry) return Boolean;

   function Current
     (Registry : Buffer_Registry) return Buffer_State;

   function Current_Access
     (Registry : in out Buffer_Registry) return access Buffer_State;

   function Buffer
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Buffer_State;

   function Buffer_Access
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id) return access Buffer_State;

   procedure Close_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Closed   : out Boolean;
      Force    : Boolean := False);

   function Find_By_Path
     (Registry : Buffer_Registry;
      Path     : String;
      Found    : out Boolean) return Buffer_Id;

   function First_Buffer
     (Registry : Buffer_Registry) return Buffer_Id;

   function Last_Buffer
     (Registry : Buffer_Registry) return Buffer_Id;

   function Next_Buffer
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Buffer_Id;

   function Previous_Buffer
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Buffer_Id;

   function Next_Buffer
     (Registry : Buffer_Registry) return Buffer_Id;

   function Previous_Buffer
     (Registry : Buffer_Registry) return Buffer_Id;

   function Display_Name
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String;

   function Display_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String;

   function Is_Dirty
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   function Is_File_Backed
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   Max_Buffer_Note_Length  : constant Natural := 160;
   Max_Buffer_Label_Length : constant Natural := 24;

   function Is_Buffer_Pinned
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   function Has_Buffer_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   function Buffer_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String;

   procedure Set_Buffer_Label
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Label    : String);

   procedure Clear_Buffer_Label
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   function Has_Buffer_Note
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   function Buffer_Note
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String;

   procedure Set_Buffer_Note
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Note     : String);

   procedure Clear_Buffer_Note
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   function Has_Buffer_Group
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   function Buffer_Group
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String;

   procedure Assign_Buffer_Group
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Name     : String);

   procedure Clear_Buffer_Group
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   function Has_Buffer_Groups
     (Registry : Buffer_Registry) return Boolean;

   function Has_Active_Buffer_Group
     (Registry : Buffer_Registry) return Boolean;

   function Active_Buffer_Group
     (Registry : Buffer_Registry) return String;

   function First_Buffer_In_Group
     (Registry : Buffer_Registry;
      Name     : String) return Buffer_Id;

   procedure Set_Active_Buffer_Group
     (Registry : in out Buffer_Registry;
      Name     : String);

   procedure Clear_Active_Buffer_Group
     (Registry : in out Buffer_Registry);

   procedure Cycle_Active_Buffer_Group
     (Registry : in out Buffer_Registry;
      Forward  : Boolean);

   function Closeable_Unpinned_Clean_Outside_Active_Group_Count
     (Registry : Buffer_Registry) return Natural;

   procedure Pin_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   procedure Unpin_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   procedure Toggle_Buffer_Pin
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   function Unpinned_Clean_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Dirty_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Dirty_File_Backed_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Dirty_Untitled_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Clean_Buffer_Count
     (Registry : Buffer_Registry) return Natural;

   function Dirty_Buffer_Display_Name
     (Registry : Buffer_Registry;
      Index    : Positive) return String;

   function Dirty_Buffer_Summary
     (Registry : Buffer_Registry)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   --  Active-buffer registry synchronization bridge.  The current editor still exposes
   --  Editor.State.State_Type as the active document projection.  These
   --  helpers keep the registry synchronized while the rest of the codebase
   --  is migrated to direct buffer-registry accessors.
   procedure Mark_Global_Provisional_Active;

   procedure Ensure_Global_Registry
     (State : in out Editor.State.State_Type);

   function Global_Registry_Current_For
     (State : Editor.State.State_Type) return Boolean;

   procedure Sync_Global_Active_From_State
     (State : Editor.State.State_Type);

   procedure Load_Global_Active_Into_State
     (State : in out Editor.State.State_Type);

   function Global_Count return Natural;
   function Global_Registry_For_UI return Buffer_Registry;
   function Global_Summary_At
     (Index : Positive) return Buffer_Summary;
   function Global_Summary_For
     (Id : Buffer_Id) return Buffer_Summary;

   function Global_Metadata_For
     (Project     : Editor.Project.Project_State;
      Id          : Buffer_Id;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Metadata_Snapshot;

   function Global_Audit_Buffers
     (Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Audit_Summary;

   function Global_Buffer_Metadata_Lifecycle_Audit_Coherent
     (Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Boolean;

   function Global_Active_Buffer return Buffer_Id;
   function Global_Contains (Id : Buffer_Id) return Boolean;
   function Global_Find_By_Path
     (Path  : String;
      Found : out Boolean) return Buffer_Id;

   --  Return True when the global registry currently has a dirty
   --  file-backed buffer for Path.  Path comparison follows the same
   --  canonical comparison as Global_Find_By_Path and performs no file
   --  mutation.
   function Global_File_Is_Dirty
     (Path : String) return Boolean;

   function Global_Next_Buffer return Buffer_Id;
   function Global_Previous_Buffer return Buffer_Id;

   function Global_Current_File return File_Identity;

   function Global_Display_Name
     (Id : Buffer_Id) return String;

   function Global_Is_Buffer_Pinned (Id : Buffer_Id) return Boolean;
   function Global_Has_Buffer_Label (Id : Buffer_Id) return Boolean;
   function Global_Buffer_Label (Id : Buffer_Id) return String;
   procedure Global_Set_Buffer_Label (Id : Buffer_Id; Label : String);
   procedure Global_Clear_Buffer_Label (Id : Buffer_Id);
   function Global_Has_Buffer_Note (Id : Buffer_Id) return Boolean;
   function Global_Buffer_Note (Id : Buffer_Id) return String;
   procedure Global_Set_Buffer_Note (Id : Buffer_Id; Note : String);
   procedure Global_Clear_Buffer_Note (Id : Buffer_Id);
   function Global_Has_Buffer_Group (Id : Buffer_Id) return Boolean;
   function Global_Buffer_Group (Id : Buffer_Id) return String;
   procedure Global_Assign_Buffer_Group (Id : Buffer_Id; Name : String);
   procedure Global_Clear_Buffer_Group (Id : Buffer_Id);
   function Global_Has_Buffer_Groups return Boolean;
   function Global_Has_Active_Buffer_Group return Boolean;
   function Global_Active_Buffer_Group return String;
   function Global_First_Buffer_In_Group (Name : String) return Buffer_Id;
   procedure Global_Set_Active_Buffer_Group (Name : String);
   procedure Global_Clear_Active_Buffer_Group;
   procedure Global_Cycle_Active_Buffer_Group (Forward : Boolean);
   function Global_Closeable_Unpinned_Clean_Outside_Active_Group_Count return Natural;
   procedure Global_Pin_Buffer (Id : Buffer_Id);
   procedure Global_Unpin_Buffer (Id : Buffer_Id);
   procedure Global_Toggle_Buffer_Pin (Id : Buffer_Id);
   function Global_Unpinned_Clean_Buffer_Count return Natural;

   function Global_Dirty_Buffer_Count return Natural;
   function Global_Dirty_File_Backed_Buffer_Count return Natural;
   function Global_Dirty_Untitled_Buffer_Count return Natural;
   function Global_Clean_Buffer_Count return Natural;

   function Global_Dirty_Buffer_Summary
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Global_Categorized_Dirty_Buffer_Summary
     (Project : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Global_Project_Lifecycle_Dirty_Buffer_Summary
     (Project : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Global_Project_Lifecycle_Buffer_Sets
     (Project : Editor.Project.Project_State) return Buffer_Project_Lifecycle_Sets;

   function Global_Bookmark_Count return Natural;

   function Global_Has_Bookmarks return Boolean;

   procedure Global_Clear_All_Bookmarks;

   procedure Global_Prune_Stale_Bookmarks;

   procedure Global_Clear_All_Edit_History;

   procedure Reset_Global_For_Test;

   procedure Global_Add_File_Buffer
     (Path         : String;
      Display_Name : String;
      Contents     : String;
      New_Id       : out Buffer_Id);

   procedure Global_Add_Untitled_Buffer
     (New_Id : out Buffer_Id);

   procedure Global_Set_Active_Buffer
     (Id : Buffer_Id);

   procedure Global_Close_Buffer
     (Id     : Buffer_Id;
      Closed : out Boolean);

   procedure Global_Force_Close_Buffer
     (Id     : Buffer_Id;
      Closed : out Boolean);

   --  Return True when any dirty file-backed buffer is at Path or below it.
   --  Used by project-explorer filesystem operations before rename/delete.
   function Global_Has_Dirty_File_Under_Path
     (Path : String) return Boolean;

   --  Return True when any file-backed buffer, clean or dirty, is at Path or
   --  below it.  Used to prevent File Tree rename/create operations from
   --  rebasing one open buffer onto another path already represented in the
   --  registry, including stale/missing file-backed buffers.
   function Global_Has_File_Under_Path
     (Path : String) return Boolean;

   --  Rebase clean file-backed buffer paths from Old_Root to New_Root.
   --  Dirty buffers are intentionally not rewritten by this helper.
   procedure Global_Rebase_Clean_File_Paths
     (Old_Root      : String;
      New_Root      : String;
      Rebased_Count : out Natural);

   --  Close every clean file-backed buffer at Path or below it.
   --  Dirty buffers are intentionally left open and must be guarded first.
   procedure Global_Close_Clean_File_Paths_Under
     (Path         : String;
      Closed_Count : out Natural);

   procedure Global_Set_Blocked_Close_Surfaced
     (Id : Buffer_Id);

   --  Clear transient lifecycle/recovery flags for a clean restored buffer.
   --  Dirty buffers intentionally preserve their recovery context.
   procedure Global_Clear_Clean_Reopen_Lifecycle
     (Id : Buffer_Id);

private
   type Buffer_State_Access is access Buffer_State;

   type Buffer_Record is record
      Id        : Buffer_Id := No_Buffer;
      State     : Buffer_State_Access := null;
      Undo      : Editor.History.History_Vector.Vector;
      Redo      : Editor.History.History_Vector.Vector;
      View      : Editor.View_Types.View_State;
      Pinned    : Boolean := False;
      Has_Group : Boolean := False;
      Group     : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Label : Boolean := False;
      Label     : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Note  : Boolean := False;
      Note      : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   function "=" (Left, Right : Buffer_Record) return Boolean;

   package Buffer_Record_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Buffer_Record,
      "="          => "=");

   type Buffer_Registry is record
      Next_Id : Buffer_Id := 1;
      Active  : Buffer_Id := No_Buffer;
      Items   : Buffer_Record_Vectors.Vector;
      Has_Active_Group : Boolean := False;
      Active_Group     : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

end Editor.Buffers;
