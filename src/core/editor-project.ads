with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package Editor.Project is

   type Project_Open_Status is
     (Project_Open_Ok,
      Project_Open_Invalid_Path,
      Project_Open_Not_Found,
      Project_Open_Not_Directory,
      Project_Open_Permission_Denied,
      Project_Open_Error);

   type Project_State is private;

   type Project_File_Refresh_Status is
     (Project_File_Refresh_Ok,
      Project_File_Refresh_No_Project,
      Project_File_Refresh_Invalid_Root,
      Project_File_Refresh_Root_Not_Found,
      Project_File_Refresh_Root_Not_Directory,
      Project_File_Refresh_Permission_Denied,
      Project_File_Refresh_Read_Error);

   type Project_Create_Path_Validation_Status is
     (Project_Create_Path_Ok,
      Project_Create_Path_No_Project,
      Project_Create_Path_Invalid_Root,
      Project_Create_Path_Ignored,
      Project_Create_Path_Ignore_Read_Error);

   type Project_Create_Path_Validation_Result is record
      Status : Project_Create_Path_Validation_Status := Project_Create_Path_No_Project;
      Failure_Reason : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Project_File_Refresh_Result is record
      Status                  : Project_File_Refresh_Status :=
        Project_File_Refresh_No_Project;
      Total_Count             : Natural := 0;
      Previous_Count          : Natural := 0;
      Added_Count             : Natural := 0;
      Removed_Count           : Natural := 0;
      Unchanged_Count         : Natural := 0;
      Skipped_Directory_Count : Natural := 0;
      Ignored_Path_Count      : Natural := 0;
      Invalid_Ignore_Pattern_Count : Natural := 0;
      Failure_Reason          : Ada.Strings.Unbounded.Unbounded_String;
   end record;


   type Project_File_Entry is record
      Relative_Path : Ada.Strings.Unbounded.Unbounded_String;
      Absolute_Path : Ada.Strings.Unbounded.Unbounded_String;
   end record;


   type Project_Open_Result is record
      Status       : Project_Open_Status := Project_Open_Invalid_Path;
      Root_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String;
      Error_Text   : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   --  Clear the editor-global project root.
   --  @param State project state to reset
   procedure Clear
     (State : in out Project_State);

   --  Return whether a project root is currently active.
   --  @param State project state to query
   --  @return True when State stores an active project root
   function Has_Project
     (State : Project_State) return Boolean;

   --  Return the stored project root path.
   --  @param State project state to query
   --  @return root path, or the empty string when no project is active
   function Root_Path
     (State : Project_State) return String;

   --  Return the stored project display name.
   --  @param State project state to query
   --  @return display name, or the empty string when no project is active
   function Display_Name
     (State : Project_State) return String;

   --  Validate a directory path as an editor project root.
   --  @param Path host filesystem directory path to open as a project
   --  @return project-open result without mutating editor state
   function Open_Project
     (Path : String) return Project_Open_Result;

   --  Test whether a project-open result is successful.
   --  @param Result project-open result to inspect
   --  @return True only when Result.Status is Project_Open_Ok
   function Is_Success
     (Result : Project_Open_Result) return Boolean;

   --  Convert a project-open result to a stable user-facing reason string.
   --  @param Result project-open result to describe
   --  @return concise success or failure message
   function Status_Message
     (Result : Project_Open_Result) return String;

   --  Apply a successful project-open result to project state.
   --  Failed results intentionally leave State unchanged.
   --  @param State project state to mutate
   --  @param Result project-open result to apply
   procedure Apply_Open_Result
     (State  : in out Project_State;
      Result : Project_Open_Result);

   --  Derive a basename-style project display name from a host path.
   --  @param Path host filesystem path
   --  @return final path component, or Path when no component can be derived
   function Display_Name_For_Path
     (Path : String) return String;

   --  Test whether Path is the active project root or under it.
   --  @param State project state that owns the root
   --  @param Path host filesystem path to test
   --  @return True when Path is inside the active project root
   function Is_Under_Project
     (State : Project_State;
      Path  : String) return Boolean;

   --  Derive a display-only path relative to the active project root.
   --  The stored file identity path must remain the real file path.
   --  @param State project state that owns the root
   --  @param Path host filesystem path to display
   --  @return relative display path, "." for the root, or Path when outside
   function Relative_Path
     (State : Project_State;
      Path  : String) return String;

   --  Replace the transient in-memory list of files known for the active
   --  project.  This is a project/session seam for surfaces such as Project
   --  Quick Open; it does not scan the filesystem or persist file views.
   procedure Clear_Known_Files
     (State : in out Project_State);

   procedure Add_Known_File
     (State         : in out Project_State;
      Relative_Path : String;
      Absolute_Path : String);

   function Known_File_Count
     (State : Project_State) return Natural;

   function Known_File_At
     (State : Project_State;
      Index : Positive) return Project_File_Entry;

   function Has_Known_File
     (State : Project_State;
      Relative_Path : String) return Boolean;

   function Absolute_Project_File_Path
     (State : Project_State;
      Relative_Path : String) return String;

   function Validate_Project_Create_Path_Rules
     (State : Project_State;
      Relative_Path : String) return Project_Create_Path_Validation_Result;

   procedure Refresh_Known_Files
     (State  : in out Project_State;
      Result : out Project_File_Refresh_Result);

   function Has_Last_Refresh_Summary
     (State : Project_State) return Boolean;

   function Last_Refresh_Summary
     (State : Project_State) return Project_File_Refresh_Result;

private
   package Project_File_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Project_File_Entry);

   type Project_State is record
      Has_Root     : Boolean := False;
      Root_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String;
      Known_Files  : Project_File_Vectors.Vector;
      Has_Last_Refresh : Boolean := False;
      Last_Refresh     : Project_File_Refresh_Result;
   end record;

end Editor.Project;
