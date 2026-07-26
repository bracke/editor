with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.State_Buffer is

   package Line_Start_Vectors is new Ada.Containers.Vectors
      (Index_Type   => Natural,
       Element_Type => Natural);

   type File_Conflict_Kind is
     (No_File_Conflict,
      External_Modified_While_Clean,
      External_Modified_While_Dirty,
      Backing_File_Deleted_While_Clean,
      Backing_File_Deleted_While_Dirty,
      Backing_File_Unreadable,
      Backing_File_Unwritable,
      Backing_File_Replaced,
      Save_Target_Parent_Missing);

   type File_Conflict_Action is
     (No_File_Conflict_Action,
      File_Conflict_Keep_Buffer,
      File_Conflict_Reload_From_Disk,
      File_Conflict_Overwrite_Disk,
      File_Conflict_Cancel);

   type Dirty_Close_Scope is
     (No_Dirty_Close_Scope,
      Active_Buffer_Close_Scope,
      Selected_Buffer_Close_Scope,
      All_Buffers_Close_Scope,
      Transition_Buffer_Close_Scope);

   type File_State is record
      Has_Path     : Boolean := False;
      Path         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("Untitled");
      Dirty        : Boolean := False;
      Baseline_Valid   : Boolean := False;
      Saved_Generation : Natural := 0;
      Last_Save_Failed   : Boolean := False;
      Last_Reload_Failed : Boolean := False;
      Last_Revert_Failed : Boolean := False;
      Missing_Target_Surfaced    : Boolean := False;
      Unreadable_Target_Surfaced : Boolean := False;
      Unwritable_Target_Surfaced : Boolean := False;
      External_Change_Surfaced   : Boolean := False;
      Blocked_Close_Surfaced     : Boolean := False;
      File_Token_Known : Boolean := False;
      File_Token_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   Max_Reopen_Candidates : constant Natural := 16;
   subtype Reopen_Candidate_Index is Positive range 1 .. Max_Reopen_Candidates;
   type Reopen_Candidate_Array is
     array (Reopen_Candidate_Index) of Ada.Strings.Unbounded.Unbounded_String;

end Editor.State_Buffer;
