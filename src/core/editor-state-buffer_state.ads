with Editor.State_Buffer;

package Editor.State.Buffer_State is

   package Line_Start_Vectors renames Editor.State_Buffer.Line_Start_Vectors;

   subtype File_Conflict_Kind is Editor.State_Buffer.File_Conflict_Kind;
   No_File_Conflict : constant File_Conflict_Kind :=
     Editor.State_Buffer.No_File_Conflict;
   External_Modified_While_Clean : constant File_Conflict_Kind :=
     Editor.State_Buffer.External_Modified_While_Clean;
   External_Modified_While_Dirty : constant File_Conflict_Kind :=
     Editor.State_Buffer.External_Modified_While_Dirty;
   Backing_File_Deleted_While_Clean : constant File_Conflict_Kind :=
     Editor.State_Buffer.Backing_File_Deleted_While_Clean;
   Backing_File_Deleted_While_Dirty : constant File_Conflict_Kind :=
     Editor.State_Buffer.Backing_File_Deleted_While_Dirty;
   Backing_File_Unreadable : constant File_Conflict_Kind :=
     Editor.State_Buffer.Backing_File_Unreadable;
   Backing_File_Unwritable : constant File_Conflict_Kind :=
     Editor.State_Buffer.Backing_File_Unwritable;
   Backing_File_Replaced : constant File_Conflict_Kind :=
     Editor.State_Buffer.Backing_File_Replaced;
   Save_Target_Parent_Missing : constant File_Conflict_Kind :=
     Editor.State_Buffer.Save_Target_Parent_Missing;

   subtype File_Conflict_Action is Editor.State_Buffer.File_Conflict_Action;
   No_File_Conflict_Action : constant File_Conflict_Action :=
     Editor.State_Buffer.No_File_Conflict_Action;
   File_Conflict_Keep_Buffer : constant File_Conflict_Action :=
     Editor.State_Buffer.File_Conflict_Keep_Buffer;
   File_Conflict_Reload_From_Disk : constant File_Conflict_Action :=
     Editor.State_Buffer.File_Conflict_Reload_From_Disk;
   File_Conflict_Overwrite_Disk : constant File_Conflict_Action :=
     Editor.State_Buffer.File_Conflict_Overwrite_Disk;
   File_Conflict_Cancel : constant File_Conflict_Action :=
     Editor.State_Buffer.File_Conflict_Cancel;

   subtype Dirty_Close_Scope is Editor.State_Buffer.Dirty_Close_Scope;
   No_Dirty_Close_Scope : constant Dirty_Close_Scope :=
     Editor.State_Buffer.No_Dirty_Close_Scope;
   Active_Buffer_Close_Scope : constant Dirty_Close_Scope :=
     Editor.State_Buffer.Active_Buffer_Close_Scope;
   Selected_Buffer_Close_Scope : constant Dirty_Close_Scope :=
     Editor.State_Buffer.Selected_Buffer_Close_Scope;
   All_Buffers_Close_Scope : constant Dirty_Close_Scope :=
     Editor.State_Buffer.All_Buffers_Close_Scope;
   Transition_Buffer_Close_Scope : constant Dirty_Close_Scope :=
     Editor.State_Buffer.Transition_Buffer_Close_Scope;

   subtype File_State is Editor.State_Buffer.File_State;
   Max_Reopen_Candidates : constant Natural :=
     Editor.State_Buffer.Max_Reopen_Candidates;
   subtype Reopen_Candidate_Index is Editor.State_Buffer.Reopen_Candidate_Index;
   subtype Reopen_Candidate_Array is Editor.State_Buffer.Reopen_Candidate_Array;

end Editor.State.Buffer_State;
