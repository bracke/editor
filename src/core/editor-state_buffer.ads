with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Command_Ids;
with Editor.Input_Field;

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

   type Buffer_Lifecycle_State is record
      File_Info : File_State;

      Reopen_Candidate_Count : Natural := 0;
      Reopen_Candidate_Paths : Reopen_Candidate_Array :=
        (others => Ada.Strings.Unbounded.Null_Unbounded_String);
      Reopen_Candidate_Labels : Reopen_Candidate_Array :=
        (others => Ada.Strings.Unbounded.Null_Unbounded_String);
      Has_Reopen_Candidate : Boolean := False;
      Reopen_Candidate_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Reopen_Candidate_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;

      Registry_Token       : Natural := 0;
      Active_Buffer_Token : Natural := 0;
      Buffer_Revision     : Natural := 0;
      Lifecycle_Generation : Natural := 0;

      File_Target_Prompt_Active : Boolean := False;
      File_Target_Prompt_Command : Editor.Command_Ids.Command_Id :=
        Editor.Command_Ids.No_Command;
      File_Target_Prompt_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Target_Prompt_Input : Editor.Input_Field.Input_Field_State;

      File_Conflict_Prompt_Active : Boolean := False;
      File_Conflict_Prompt_Buffer : Natural := 0;
      File_Conflict_Prompt_Path : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Conflict_Prompt_Display : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Conflict_Prompt_Kind : File_Conflict_Kind := No_File_Conflict;
      File_Conflict_Prompt_Dirty : Boolean := False;
      File_Conflict_Prompt_Buffer_Revision : Natural := 0;
      File_Conflict_Prompt_Token_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;

      File_Conflict_Close_After_Overwrite : Boolean := False;
      File_Conflict_Close_After_Overwrite_Buffer : Natural := 0;
      File_Conflict_Close_After_Overwrite_Selected : Boolean := False;
      File_Conflict_Close_After_Overwrite_All_Buffers : Boolean := False;

      Dirty_Close_Prompt_Active : Boolean := False;
      Dirty_Close_Prompt_Scope : Dirty_Close_Scope := No_Dirty_Close_Scope;
      Dirty_Close_Prompt_All_Buffers : Boolean := False;
      Dirty_Close_Prompt_Buffer : Natural := 0;
      Dirty_Close_Prompt_Buffer_Count : Natural := 0;
      Dirty_Close_Prompt_Buffer_Fingerprint : Natural := 0;
      Dirty_Close_Prompt_Buffer_Ids : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Dirty_Close_Prompt_Dirty_Fingerprint : Natural := 0;
      Dirty_Close_Prompt_Dirty_Buffer_Ids : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Dirty_Close_Prompt_Dirty_Count : Natural := 0;
      Dirty_Close_Prompt_File_Backed_Count : Natural := 0;
      Dirty_Close_Prompt_Untitled_Count : Natural := 0;
      Dirty_Close_Prompt_Conflicted_Count : Natural := 0;
      Dirty_Close_Prompt_Unwritable_Count : Natural := 0;
      Dirty_Close_Prompt_Missing_Count : Natural := 0;
      Dirty_Close_Prompt_Save_Failure_Count : Natural := 0;
   end record;

end Editor.State_Buffer;
